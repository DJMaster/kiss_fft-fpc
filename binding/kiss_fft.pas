//
// kiss_fft.h header binding for the Free Pascal Compiler aka FPC
//
// Binaries and demos available at http://www.djmaster.com/
//

unit kiss_fft;

{$mode objfpc}{$H+}

interface

uses
  ctypes;

type
  pcsize_t = ^csize_t;
  
const
  LIB_KISS_FFT = 'kiss_fft.dll';

// #include <stdlib.h>
// #include <stdio.h>
// #include <math.h>
// #include <string.h>

(*
 ATTENTION!
 If you would like a :
 -- a utility that will handle the caching of fft objects
 -- real-only (no imaginary time component ) FFT
 -- a multi-dimensional FFT
 -- a command-line utility to perform ffts
 -- a command-line utility to perform fast-convolution filtering

 Then see kfc.h kiss_fftr.h kiss_fftnd.h fftutil.c kiss_fastfir.c
  in the tools/ directory.
*)

// #ifdef USE_SIMD
// # include <xmmintrin.h>
// # define kiss_fft_scalar __m128
// #define KISS_FFT_MALLOC(nbytes) _mm_malloc(nbytes,16)
// #define KISS_FFT_FREE _mm_free
// #else	
// #define KISS_FFT_MALLOC malloc
// #define KISS_FFT_FREE free
// #endif	

{$ifdef FIXED_POINT}
{$if (FIXED_POINT == 32)}
type
  kiss_fft_scalar = cint32;
{$else}
type
  kiss_fft_scalar = cint16;
{$endif}
{$else} (* FIXED_POINT *)
{$ifndef kiss_fft_scalar}
(*  default is float *)
type
  kiss_fft_scalar = cfloat;
{$endif}
{$endif} (* FIXED_POINT *)

type
  kiss_fft_cpx = record
    r: kiss_fft_scalar;
    i: kiss_fft_scalar;
  end;
  Pkiss_fft_cpx = ^kiss_fft_cpx;

type
  kiss_fft_state = record
  end;
  kiss_fft_cfg = ^kiss_fft_state;

(* 
 *  kiss_fft_alloc
 *  
 *  Initialize a FFT (or IFFT) algorithm's cfg/state buffer.
 *
 *  typical usage:      kiss_fft_cfg mycfg=kiss_fft_alloc(1024,0,NULL,NULL);
 *
 *  The return value from fft_alloc is a cfg buffer used internally
 *  by the fft routine or NULL.
 *
 *  If lenmem is NULL, then kiss_fft_alloc will allocate a cfg buffer using malloc.
 *  The returned value should be free()d when done to avoid memory leaks.
 *  
 *  The state can be placed in a user supplied buffer 'mem':
 *  If lenmem is not NULL and mem is not NULL and *lenmem is large enough,
 *      then the function places the cfg in mem and the size used in *lenmem
 *      and returns mem.
 *  
 *  If lenmem is not NULL and ( mem is NULL or *lenmem is not large enough),
 *      then the function returns NULL and places the minimum cfg 
 *      buffer size in *lenmem.
 * *)
function kiss_fft_alloc(nfft: cint; inverse_fft: cint; mem: pointer; lenmem: pcsize_t): kiss_fft_cfg; cdecl; external LIB_KISS_FFT;

(*
 * kiss_fft(cfg,in_out_buf)
 *
 * Perform an FFT on a complex input buffer.
 * for a forward FFT,
 * fin should be  f[0] , f[1] , ... ,f[nfft-1]
 * fout will be   F[0] , F[1] , ... ,F[nfft-1]
 * Note that each element is complex and can be accessed like
    f[k].r and f[k].i
 * *)
procedure kiss_fft(cfg: kiss_fft_cfg; const fin: Pkiss_fft_cpx; fout: Pkiss_fft_cpx); cdecl; external LIB_KISS_FFT;

(*
 A more generic version of the above function. It reads its input from every Nth sample.
 * *)
procedure kiss_fft_stride(cfg: kiss_fft_cfg; const fin: Pkiss_fft_cpx; fout: Pkiss_fft_cpx; fin_stride: cint); cdecl; external LIB_KISS_FFT;

(* If kiss_fft_alloc allocated a buffer, it is one contiguous 
   buffer and can be simply free()d when no longer needed*)
procedure kiss_fft_free(cfg: kiss_fft_cfg); cdecl;

(*
 Cleans up some memory that gets managed internally. Not necessary to call, but it might clean up 
 your compiler output to call this before you exit.
*)
procedure kiss_fft_cleanup(); cdecl; external LIB_KISS_FFT;

(*
 * Returns the smallest integer k, such that k>=n and k has only "fast" factors (2,3,5)
 *)
function kiss_fft_next_fast_size(n: cint): cint; cdecl; external LIB_KISS_FFT;

(* for real ffts, we need an even size *)
function kiss_fftr_next_fast_size_real(n: cint): cint; cdecl;

implementation

procedure kiss_fft_free(cfg: kiss_fft_cfg); cdecl;
begin
  Dispose(cfg);
end;

function kiss_fftr_next_fast_size_real(n: cint): cint; cdecl;
begin
  Result := kiss_fft_next_fast_size(((n+1) shr 1) shl 1);
end;

end.

