// Copyright 2013 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build linux

package runtime

import (
	"runtime/internal/atomic"
	"unsafe"
)

//extern epoll_create
func epollcreate(size int32) int32

//extern epoll_create1
func epollcreate1(flags int32) int32

//go:noescape
//extern epoll_ctl
func epollctl(epfd, op, fd int32, ev *epollevent) int32

//go:noescape
//extern epoll_wait
func epollwait(epfd int32, ev *epollevent, nev, timeout int32) int32

var (
	epfd int32 = -1 // epoll descriptor

	netpollBreakRd, netpollBreakWr uintptr // for netpollBreak

	netpollWakeSig uint32 // used to avoid duplicate calls of netpollBreak
)

func netpollinit() {
	epfd = epollcreate1(_EPOLL_CLOEXEC)
	if epfd < 0 {
		epfd = epollcreate(1024)
		if epfd < 0 {
			println("runtime: epollcreate failed with", -epfd)
			throw("runtime: netpollinit failed")
		}
		closeonexec(epfd)
	}
	r, w, cerrno := nonblockingPipe()
	if cerrno != 0 {
		println("runtime: pipe failed with", cerrno)
		throw("runtime: pipe failed")
	}
	ev := epollevent{
		events: _EPOLLIN,
	}
	*(**uintptr)(unsafe.Pointer(&ev.data)) = &netpollBreakRd
	if epollctl(epfd, _EPOLL_CTL_ADD, r, &ev) < 0 {
		cerrno = int32(errno())
	}
	if cerrno != 0 {
		println("runtime: epollctl failed with", cerrno)
		throw("runtime: epollctl failed")
	}
	netpollBreakRd = uintptr(r)
	netpollBreakWr = uintptr(w)
}

func netpollIsPollDescriptor(fd uintptr) bool {
	return fd == uintptr(epfd) || fd == netpollBreakRd || fd == netpollBreakWr
}

func netpollopen(fd uintptr, pd *pollDesc) int32 {
	var ev epollevent
	ev.events = _EPOLLIN | _EPOLLOUT | _EPOLLRDHUP | _EPOLLETpos
	*(**pollDesc)(unsafe.Pointer(&ev.data)) = pd
	if epollctl(epfd, _EPOLL_CTL_ADD, int32(fd), &ev) < 0 {
		return int32(errno())
	}
	return 0
}

func netpollclose(fd uintptr) int32 {
	var ev epollevent
	if epollctl(epfd, _EPOLL_CTL_DEL, int32(fd), &ev) < 0 {
		return int32(errno())
	}
	return 0
}

func netpollarm(pd *pollDesc, mode int) {
	throw("runtime: unused")
}

// netpollBreak interrupts an epollwait.
func netpollBreak() {
	if atomic.Cas(&netpollWakeSig, 0, 1) {
		for {
			var b byte
			n := write(netpollBreakWr, unsafe.Pointer(&b), 1)
			if n == 1 {
				break
			}
			if n == -_EINTR {
				continue
			}
			if n == -_EAGAIN {
				return
			}
			println("runtime: netpollBreak write failed with", -n)
			throw("runtime: netpollBreak write failed")
		}
	}
}

// netpoll checks for ready network connections.
// Returns list of goroutines that become runnable.
// delay < 0: blocks indefinitely
// delay == 0: does not block, just polls
// delay > 0: block for up to that many nanoseconds
func netpoll(delay int64) gList {
	if epfd == -1 {
		return gList{}
	}
	var waitms int32
	if delay < 0 {
		waitms = -1
	} else if delay == 0 {
		waitms = 0
	} else if delay < 1e6 {
		waitms = 1
	} else if delay < 1e15 {
		waitms = int32(delay / 1e6)
	} else {
		// An arbitrary cap on how long to wait for a timer.
		// 1e9 ms == ~11.5 days.
		waitms = 1e9
	}
	var events [128]epollevent
retry:
	n := epollwait(epfd, &events[0], int32(len(events)), waitms)
	if n < 0 {
		e := errno()
		if e != _EINTR {
			println("runtime: epollwait on fd", epfd, "failed with", e)
			throw("runtime: netpoll failed")
		}
		// If a timed sleep was interrupted, just return to
		// recalculate how long we should sleep now.
		if waitms > 0 {
			return gList{}
		}
		goto retry
	}
	var toRun gList
	for i := int32(0); i < n; i++ {
		ev := &events[i]
		if ev.events == 0 {
			continue
		}

		if *(**uintptr)(unsafe.Pointer(&ev.data)) == &netpollBreakRd {
			if ev.events != _EPOLLIN {
				println("runtime: netpoll: break fd ready for", ev.events)
				throw("runtime: netpoll: break fd ready for something unexpected")
			}
			if delay != 0 {
				// netpollBreak could be picked up by a
				// nonblocking poll. Only read the byte
				// if blocking.
				var tmp [16]byte
				read(int32(netpollBreakRd), noescape(unsafe.Pointer(&tmp[0])), int32(len(tmp)))
				atomic.Store(&netpollWakeSig, 0)
			}
			continue
		}

		var mode int32
		if ev.events&(_EPOLLIN|_EPOLLRDHUP|_EPOLLHUP|_EPOLLERR) != 0 {
			mode += 'r'
		}
		if ev.events&(_EPOLLOUT|_EPOLLHUP|_EPOLLERR) != 0 {
			mode += 'w'
		}
		if mode != 0 {
			pd := *(**pollDesc)(unsafe.Pointer(&ev.data))
			pd.setEventErr(ev.events == _EPOLLERR)
			netpollready(&toRun, pd, mode)
		}
	}
	return toRun
}
