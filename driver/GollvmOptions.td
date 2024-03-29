//===--- Options.td - Options for gollvm ----------------------------------===//
//
// Copyright 2018 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
//===----------------------------------------------------------------------===//
//
//  This file defines the command line options options accepted by llvm-goc,
//  the Gollvm compiler.
//
//===----------------------------------------------------------------------===//

// Include the common option parsing interfaces.
include "llvm/Option/OptParser.td"

/////////
// Flags

// DriverOption - The option is a "driver" option, and should not be forwarded
// to other tools.
def DriverOption : OptionFlag;

// LinkerInput - The option is a linker input.
def LinkerInput : OptionFlag;

// Unsupported - The option is unsupported, and the driver will reject command
// lines that use it.
def Unsupported : OptionFlag;

// Ignored - The option is unsupported, and the driver will silently ignore it.
def Ignored : OptionFlag;

// A short name to show in documentation. The name will be interpreted as rST.
class DocName<string name> { string DocName = name; }

// A brief description to show in documentation, interpreted as rST.
class DocBrief<code descr> { code DocBrief = descr; }

// Indicates that this group should be flattened into its parent when generating
// documentation.
class DocFlatten { bit DocFlatten = 1; }

/////////
// Groups

def Action_Group : OptionGroup<"<action group>">, DocName<"Actions">,
                   DocBrief<[{The action to perform on the input.}]>;

// Meta-group for options which are only used for compilation,
// and not linking etc.
def CompileOnly_Group : OptionGroup<"<CompileOnly group>">,
                        DocName<"Compilation flags">, DocBrief<[{
Flags controlling the behavior of gollvm during compilation. These flags have
no effect during actions that do not perform compilation.}]>;

def O_Group : OptionGroup<"<O group>">, Group<CompileOnly_Group>,
              DocName<"Optimization level">, DocBrief<[{
Flags controlling how much optimization should be performed.}]>;

def f_Group : OptionGroup<"<f group>">, Group<CompileOnly_Group>,
              DocName<"Target-independent compilation options">;

def m_Group : OptionGroup<"<m group>">, Group<CompileOnly_Group>,
              DocName<"Target-dependent compilation options">;

def R_Group : OptionGroup<"<R group>">, Group<CompileOnly_Group>,
              DocName<"Optimization remark control options">;

def DebugInfo_Group : OptionGroup<"<g group>">, Group<CompileOnly_Group>,
                      DocName<"Debug information generation">, DocBrief<[{
Flags controlling how much and what kind of debug information should be
generated.}]>;

def Link_Group : OptionGroup<"<T/e/s/t/u group>">, DocName<"Linker flags">,
                 DocBrief<[{Flags that are passed on to the linker}]>;

def Developer_Group : OptionGroup<"<dev group>">, DocName<"Developer flags">,
                 DocBrief<[{Flags mainly of interest to gollvm developers.}]>;

// To be added later: arch-specific groups.

/////////
// Options

// The internal option ID must be a valid C++ identifier and results in a
// proper OPT_XX enum constant for XX.
//
// We want to unambiguously be able to refer to options from the driver source
// code, for this reason the option name is mangled into an ID. This mangling
// isn't guaranteed to have an inverse, but for practical purposes it does.
//
// The mangling scheme is to ignore the leading '-', and perform the following
// substitutions:
//   _ => __
//   - => _
//   / => _SLASH
//   # => _HASH
//   ? => _QUESTION
//   , => _COMMA
//   = => _EQ
//   C++ => CXX
//   . => _

// Standard Options

def help : Flag<["-", "--"], "help">,
  HelpText<"Display available options">;

def version : Flag<["--"], "version">,
  HelpText<"Display compiler version information.">;

def B : JoinedOrSeparate<["-"], "B">,
    Flags<[DriverOption]>, MetaVarName<"<prefix>">,
    HelpText<"Add prefix for searching binaries and libraries">;

def I : JoinedOrSeparate<["-"], "I">,
    Flags<[DriverOption]>, MetaVarName<"<dir>">,
    HelpText<"Add include directory to be searched for packages">;

def L : JoinedOrSeparate<["-"], "L">, Group<Link_Group>,
    Flags<[RenderJoined]>, MetaVarName<"<dir>">,
    HelpText<"Add library directory to linker search path">;

def l : JoinedOrSeparate<["-"], "l">, Flags<[RenderJoined]>,
        Group<Link_Group>;

def z : JoinedOrSeparate<["-"], "z">, Flags<[RenderJoined]>,
        Group<Link_Group>;

def D : JoinedOrSeparate<["-"], "D">, Group<CompileOnly_Group>,
    Flags<[Ignored]>, MetaVarName<"<macro>=<value>">,
    HelpText<"This option is ignored">;

def isystem : JoinedOrSeparate<["-"], "isystem">, Group<CompileOnly_Group>,
  Flags<[Ignored]>,
  HelpText<"This option is ignored">, MetaVarName<"<directory>">;

def O : Joined<["-"], "O">, Group<O_Group>,
    HelpText<"Set optimization level">;

def O_flag : Flag<["-"], "O">, Alias<O>, AliasArgs<["2"]>,
    HelpText<"Set optimization level to -O2">;

def S : Flag<["-"], "S">, Flags<[DriverOption]>, Group<Action_Group>,
  HelpText<"Only run compilation step">;

def fintegrated_as : Flag<["-"], "fintegrated-as">,
                     Group<Action_Group>, HelpText<"Enable the integrated assembler">;

def fno_integrated_as : Flag<["-"], "fno-integrated-as">,
                        Group<Action_Group>,
                        HelpText<"Disable the integrated assembler">;

def c : Flag<["-"], "c">, Flags<[DriverOption]>, Group<Action_Group>,
  HelpText<"Only run compile and assemble steps">;

def o : JoinedOrSeparate<["-"], "o">, Flags<[DriverOption, RenderAsInput]>,
  HelpText<"Write output to <file>">, MetaVarName<"<file>">;

def g_Flag : Flag<["-"], "g">, Group<DebugInfo_Group>,
  HelpText<"Generate source-level debug information">;

def gz : Flag<["-"], "gz">, Group<DebugInfo_Group>,
    HelpText<"DWARF debug sections compression type">;

def gz_EQ : Joined<["-"], "gz=">, Group<DebugInfo_Group>,
    HelpText<"DWARF debug sections compression type">;

def grecord_gcc_switches : Flag<["-"], "grecord-gcc-switches">,
    Group<DebugInfo_Group>;
def gno_record_gcc_switches : Flag<["-"], "gno-record-gcc-switches">,
    Group<DebugInfo_Group>;

def sysroot_EQ : Joined<["--"], "sysroot=">;
def sysroot : Separate<["--"], "sysroot">, Alias<sysroot_EQ>;

def target_EQ : Joined<["--"], "target=">, Flags<[DriverOption]>,
  HelpText<"Generate code for the given target">;

def v : Flag<["-"], "v">,
  HelpText<"Show commands to run and use verbose output">;

def x : JoinedOrSeparate<["-"], "x">, Flags<[DriverOption]>,
  HelpText<"Treat subsequent input files as having type <language>">;

def _HASH_HASH_HASH : Flag<["-"], "###">, Flags<[DriverOption]>,
    HelpText<"Print (but do not run) the commands to run for this compilation">;

def dumpversion : Flag<["-"], "dumpversion">,
  HelpText<"Emit version number and exit.">;

def dumpmachine : Flag<["-"], "dumpmachine">,
  HelpText<"Emit target machine and exit.">;

def print_file_name_EQ : Joined<["-", "--"], "print-file-name=">,
  HelpText<"Print the full library path of <file>">, MetaVarName<"<file>">;

def print_prog_name_EQ : Joined<["-", "--"], "print-prog-name=">,
  HelpText<"Print the full program path of <name>">, MetaVarName<"<name>">;

def print_multi_lib : Flag<["--"], "print-multi-lib">,
  HelpText<"Emit the mapping from multilib directory names to compiler "
           "flags that enable them">;

def w : Flag<["-"], "w">,
  HelpText<"Suppress warning messages">;
def no_warn : Flag<["-"], "no-warm">, Alias<w>;

def save_temps : Flag<["-", "--"], "save-temps">, Flags<[DriverOption]>,
  HelpText<"Save intermediate compilation results">;

def config : Flag<["--"], "config">, Flags<[Unsupported]>;

def Wa_COMMA : CommaJoined<["-"], "Wa,">,
  HelpText<"Pass the comma separated arguments in <arg> to the assembler">,
  MetaVarName<"<arg>">;

def Xassembler : Separate<["-"], "Xassembler">,
  HelpText<"Pass <arg> to the assembler">, MetaVarName<"<arg>">,
  Group<CompileOnly_Group>;

def Wl_COMMA : CommaJoined<["-"], "Wl,">, Flags<[LinkerInput, RenderAsInput]>,
  HelpText<"Pass the comma separated arguments in <arg> to the linker">,
  MetaVarName<"<arg>">, Group<Link_Group>;

def Xlinker : Separate<["-"], "Xlinker">, Flags<[LinkerInput, RenderAsInput]>,
  HelpText<"Pass <arg> to the linker">, MetaVarName<"<arg>">,
  Group<Link_Group>;

def pie : Flag<["-"], "pie">;
def nopie : Flag<["-"], "nopie">;
def no_pie : Flag<["-"], "no-pie">, Alias<nopie>;

def shared : Flag<["-", "--"], "shared">;
def static : Flag<["-", "--"], "static">;

def nostdlib : Flag<["-"], "nostdlib">;

def static_libgo : Flag<["-", "--"], "static-libgo">;
def static_libgcc : Flag<["-", "--"], "static-libgcc">;

def pthreads : Flag<["-"], "pthreads">,
  HelpText<"Support POSIX threads in generated code">;
def pthread : Flag<["-"], "pthread">, Alias<pthreads>,
  HelpText<"Support POSIX threads in generated code">;

// Target-independent "-f" options.

def fsplit_stack : Flag<["-"], "fsplit-stack">, Group<f_Group>,
  HelpText<"Use split stacks">;
def fno_split_stack : Flag<["-"], "fno-split-stack">, Group<f_Group>,
  HelpText<"Don't use split stacks">;

def fPIC : Flag<["-"], "fPIC">, Group<f_Group>;
def fno_PIC : Flag<["-"], "fno-PIC">, Group<f_Group>;
def fpic : Flag<["-"], "fpic">, Group<f_Group>;
def fno_pic : Flag<["-"], "fno-pic">, Group<f_Group>;
def fPIE : Flag<["-"], "fPIE">, Group<f_Group>;
def fno_PIE : Flag<["-"], "fno-PIE">, Group<f_Group>;
def fpie : Flag<["-"], "fpie">, Group<f_Group>;
def fno_pie : Flag<["-"], "fno-pie">, Group<f_Group>;


def fno_inline : Flag<["-"], "fno-inline">, Group<f_Group>,
  HelpText<"Disable inlining">;

def fvectorize : Flag<["-"], "fvectorize">, Group<f_Group>,
  HelpText<"Enable the loop vectorization passes">;
def fno_vectorize : Flag<["-"], "fno-vectorize">, Group<f_Group>,
  HelpText<"Disable the loop vectorization passes">;

def fslp_vectorize : Flag<["-"], "fslp-vectorize">, Group<f_Group>,
  HelpText<"Enable the superword-level parallelism vectorization passes">;
def fno_slp_vectorize : Flag<["-"], "fno-slp-vectorize">, Group<f_Group>,
  HelpText<"Disable the superword-level parallelism vectorization passes">;

def ffp_contract_EQ : Joined<["-"], "ffp-contract=">, Group<f_Group>,
  HelpText<"Form fused FP ops (e.g. FMAs): fast (everywhere)"
  " | on (according to FP_CONTRACT pragma, default) | off (never fuse)">,
  Values<"fast,on,off">;

def ftrapping_math : Flag<["-"], "ftrapping-math">, Group<f_Group>,
  HelpText<"Compile code assuming that floating-point operations can"
           " generate user-visible traps.">;

def fno_trapping_math : Flag<["-"], "fno-trapping-math">, Group<f_Group>,
  HelpText<"Compile code assuming that floating-point operations cannot"
           " generate user-visible traps.">;

def fmath_errno : Flag<["-"], "fmath-errno">, Group<f_Group>,
  HelpText<"Require math functions to indicate errors by setting errno">;

def fno_math_errno : Flag<["-"], "fno-math-errno">, Group<f_Group>,
  HelpText<"Do not require math functions to indicate errors by setting errno">;

def fuse_init_array : Flag<["-"], "fuse-init-array">, Group<f_Group>,
  HelpText<"Use .init_array instead of .ctors">;

def fno_use_init_array : Flag<["-"], "fno-use-init-array">, Group<f_Group>,
  HelpText<"Don't use .init_array instead of .ctors">;

def fomit_frame_pointer : Flag<["-"], "fomit-frame-pointer">, Group<f_Group>,
  HelpText<"Allow elimination of frame pointer">;

def fno_omit_frame_pointer : Flag<["-"], "fno-omit-frame-pointer">, Group<f_Group>,
  HelpText<"Disallow elimination of frame pointer">;

def fshow_column : Flag<["-"], "fshow-column">, Group<f_Group>,
  HelpText<"Print column numbers in diagnostics">;

def fno_show_column : Flag<["-"], "fno-show-column">, Group<f_Group>,
  HelpText<"Do not print column numbers in diagnostics">;

def fuse_ld_EQ : Joined<["-"], "fuse-ld=">, Group<f_Group>;

def fdebug_prefix_map_EQ : Joined<["-"], "fdebug-prefix-map=">, Group<f_Group>,
  HelpText<"remap file source paths in debug info">;


def fprofile_sample_use : Flag<["-"], "fprofile-sample-use">, Group<f_Group>, Flags<[DriverOption]>;
def fno_profile_sample_use : Flag<["-"], "fno-profile-sample-use">, Group<f_Group>, Flags<[DriverOption]>;

def fprofile_sample_use_EQ : Joined<["-"], "fprofile-sample-use=">,
    Group<f_Group>, Flags<[DriverOption]>,
    HelpText<"Enable sample-based profile guided optimizations">;

def fdebug_info_for_profiling : Flag<["-"], "fdebug-info-for-profiling">, Group<f_Group>,
    Flags<[DriverOption]>,
    HelpText<"Emit extra debug info to make sample profile more accurate.">;
def fno_debug_info_for_profiling : Flag<["-"], "fno-debug-info-for-profiling">, Group<f_Group>,
    Flags<[DriverOption]>,
    HelpText<"Do not emit extra debug info for sample profiler.">;

def fsave_optimization_record : Flag<["-"], "fsave-optimization-record">,
    Group<f_Group>, Flags<[DriverOption]>,
    HelpText<"Generate a YAML optimization record file">;
def fno_save_optimization_record : Flag<["-"], "fno-save-optimization-record">,
    Group<f_Group>, Flags<[DriverOption]>,
    HelpText<"Do not generate a YAML optimization record file">;
def foptimization_record_file_EQ : Joined<["-"], "foptimization-record-file=">,
    Group<f_Group>, Flags<[DriverOption]>,
    HelpText<"Specify the file name of any generated YAML optimization record">;

def Rpass_EQ : Joined<["-"], "Rpass=">, Group<R_Group>,
  HelpText<"Report transformations performed by optimization passes whose "
           "name matches the given POSIX regular expression">;
def Rpass_missed_EQ : Joined<["-"], "Rpass-missed=">, Group<R_Group>,
  HelpText<"Report missed transformations by optimization passes whose "
           "name matches the given POSIX regular expression">;
def Rpass_analysis_EQ : Joined<["-"], "Rpass-analysis=">, Group<R_Group>,
  HelpText<"Report transformation analysis from optimization passes whose "
           "name matches the given POSIX regular expression">;

// Target-dependent "-m" options.

def march_EQ : Joined<["-"], "march=">, Group<m_Group>;

def mcpu_EQ : Joined<["-"], "mcpu=">, Group<m_Group>;

def m32 : Flag<["-"], "m32">, Group<m_Group>;
def mx32 : Flag<["-"], "mx32">, Group<m_Group>, Flags<[Unsupported]>;
def m64 : Flag<["-"], "m64">, Group<m_Group>;

def mllvm : Separate<["-"], "mllvm">,
  HelpText<"Additional arguments to forward to LLVM's option processing">;

// Go-related options

def fgo_check_divide_zero : Flag<["-"], "fgo-check-divide-zero">,
  Group<f_Group>,
  HelpText<"Add explicit checks for divide-by-zero">;

def fno_go_check_divide_zero : Flag<["-"], "fno-go-check-divide-zero">,
  Group<f_Group>,
  HelpText<"Do not add explicit checks for divide-by-zero">;

def fgo_check_divide_overflow : Flag<["-"], "fgo-check-divide-overflow">,
  Group<f_Group>,
  HelpText<"Add explicit checks for division overflow in INT_MIN / -1.">;

def fno_go_check_divide_overflow : Flag<["-"], "fno-go-check-divide-overflow">,
  Group<f_Group>,
  HelpText<"Do not add explicit checks for division overflow in INT_MIN / -1">;

def fgo_compiling_runtime : Flag<["-"], "fgo-compiling-runtime">,
  Group<f_Group>,
  HelpText<"Compiling the runtime package">;

def fgo_optimize_allocs : Flag<["-"], "fgo-optimize-allocs">,
  Group<f_Group>,
  HelpText<"Enable escape analysis in the go frontend">;

def fno_go_optimize_allocs : Flag<["-"], "fno-go-optimize-allocs">,
  Group<f_Group>,
  HelpText<"Disable escape analysis in the go frontend">;

def fgo_pkgpath_EQ : Joined<["-"], "fgo-pkgpath=">,
  Group<f_Group>,
  HelpText<"Set Go package path">;

def fgo_prefix_EQ : Joined<["-"], "fgo-prefix=">,
  Group<f_Group>,
  HelpText<"Set package-specific prefix for exported Go names">;

def fgo_relative_import_path_EQ : Joined<["-"], "fgo-relative-import-path=">,
  Group<f_Group>,
  HelpText<"Set package-specific prefix for exported Go names">;

def fgo_c_header_EQ : Joined<["-"], "fgo-c-header=">,
  Group<f_Group>,
  HelpText<"The C header file to write.">;

def fgo_embedcfg_EQ : Joined<["-"], "fgo-embedcfg=">,
  Group<f_Group>,
  HelpText<"List of embedded files via go:embed.">;

// Needed for compatibility with gccgo

def xassembler_with_cpp : Flag<["-"], "xassembler-with-cpp">,
    Flags<[Ignored]>, HelpText<"This option is ignored">;

def fno_toplevel_reorder : Flag<["-"], "fno-toplevel-reorder">,
    Flags<[Ignored]>, HelpText<"This option is ignored">;

def no_canonical_prefixes : Flag<["-"], "no-canonical-prefixes">,
    Flags<[Ignored]>, HelpText<"This option is ignored">;

def fno_diagnostics_show_caret : Flag<["-"], "fno-diagnostics-show-caret">,
    Flags<[Ignored]>, HelpText<"This option is ignored">;

def fbounds_check : Flag<["-"], "fbounds-check">,
    Flags<[Ignored]>, HelpText<"This option is ignored">;

def finline_functions : Flag<["-"], "finline-functions">,
    Flags<[Ignored]>, HelpText<"This option is ignored">;

def funroll_loops : Flag<["-"], "funroll-loops">,
    Flags<[Ignored]>, HelpText<"This option is ignored">;

def pedantic_errors : Flag<["-"], "pedantic-errors">,
    Flags<[Ignored]>, HelpText<"This option is ignored">;

def fdiagnostics_color_EQ : Joined<["-"], "fdiagnostics-color=">,
    Flags<[Ignored]>, HelpText<"This option is ignored">;

// Currently unsupported or not-yet-supported.

def flto : Flag<["-"], "flto">,
    Flags<[Ignored]>, HelpText<"This option is not yet supported">;

def fuse_linker_plugin : Flag<["-"], "fuse-linker-plugin">,
    Flags<[Ignored]>, HelpText<"This option is not yet supported">;

// Debugging options for gollvm developers.

def fgo_dump_ast : Flag<["-"], "fgo-dump-ast">,
  Group<Developer_Group>,
  HelpText<"Dump Go frontend internal AST structure (debugging)">;

def nobackend : Flag<["-", "--"], "nobackend">, Group<Developer_Group>,
    HelpText<"Stub out LLVM back end (run only gofrontend)">;

def noverify : Flag<["-", "--"], "noverify">, Group<Developer_Group>,
    HelpText<"Stub out module verifier invocation">;

def dump_ir : Flag<["-", "--"], "dump-ir">, Group<Developer_Group>,
    HelpText<"Dump LLVM IR for module prior to back end invocation">;

def fgo_debug_escape_EQ : Joined<["-"], "fgo-debug-escape=">,
    Group<Developer_Group>,
    HelpText<"Emit debugging information related to the escape analysis"
             " pass when run with -fgo-optimize-allocs">;

def fgo_debug_escape_hash_EQ : Joined<["-"], "fgo-debug-escape-hash=">,
    Group<Developer_Group>,
    HelpText<"A hash value to debug escape analysis. Argument is"
             " a binary string. This runs escape analysis only on"
             " functions whose names hash to values that match the"
             " given suffix. Can be used to binary search across"
             " functions to uncover escape analysis bugs.">;

def fgo_debug_optimization : Flag<["-"], "fgo-debug-optimization">,
  Group<f_Group>,
  HelpText<"Emit gofrontend optimization diagnostics">;

def fno_go_debug_optimization : Flag<["-"], "fno-go-debug-optimization">,
  Group<f_Group>,
  HelpText<"Do not emit gofrontend optimization diagnostics">;

def tracelevel_EQ : Joined<["-", "--"], "tracelevel=">, Group<Developer_Group>,
    HelpText<"Set debug trace level (def: 0, no trace output)">;

def emit_llvm : Flag<["-"], "emit-llvm">, Flags<[DriverOption]>,
  Group<Action_Group>,
  HelpText<"Use the LLVM representation for assembler and object files">;

def emit_llvm_uselists : Flag<["-"], "emit-llvm-uselists">,
  HelpText<"Preserve order of LLVM use-lists when serializing">;

def no_emit_llvm_uselists : Flag<["-"], "no-emit-llvm-uselists">,
  HelpText<"Don't preserve order of LLVM use-lists when serializing">;

def disable_llvm_passes : Flag<["-"], "disable-llvm-passes">,
  HelpText<"Use together with -emit-llvm to get pristine LLVM IR from the "
           "frontend by not running any LLVM passes at all">;

def gcc_toolchain_EQ : Joined<["--"], "gcc-toolchain=">, Flags<[DriverOption]>,
  HelpText<"Use the gcc toolchain at the given directory, the directory typically contains "
           "‘lib{,32,64}/gcc{,-cross}/$triple’ and ‘include’">;

def enable_gc_EQ : Joined<["-"], "enable-gc=">,
  HelpText<"Enable stack map generation">;
