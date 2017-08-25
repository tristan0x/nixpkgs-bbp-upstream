{ stdenv, fetchurl, gfortran, perl, liblapack, config, coreutils
# Most packages depending on openblas expect integer width to match pointer width,
# but some expect to use 32-bit integers always (for compatibility with reference BLAS).
, blas64 ? null
}:

with stdenv.lib;

let local = config.openblas.preferLocalBuild or false;
    binary =
      { i686-linux = "32";
        x86_64-linux = "64";
        x86_64-darwin = "64";
		powerpc64-linux = "64";
      }."${stdenv.system}" or (throw "unsupported system: ${stdenv.system}");
    genericFlags =
      [ "DYNAMIC_ARCH=1"
      ];
    localFlags = attrByPath [ "openblas" "flags" ]  ( 
				 	optionals (hasAttr "target" config.openblas) 
							[ "TARGET=${config.openblas.target}" ]
					) config;
    blas64Orig = blas64;
in
stdenv.mkDerivation rec {
  version = "0.2.18";

  name = "openblas-${version}";
  src = fetchurl {
    url = "https://github.com/xianyi/OpenBLAS/tarball/v${version}";
    sha256 = "0vdzivw24s94vrzw4sqyz76mj60vs27vyn3dc14yw8qfq1v2wib5";
    name = "openblas-${version}.tar.gz";
  };

  preBuild = "cp ${liblapack.src} lapack-${liblapack.meta.version}.tgz";

  nativeBuildInputs = optionals stdenv.isDarwin [coreutils] ++ [gfortran perl];

  makeFlags =
    (if local then localFlags else genericFlags)
    ++
    optionals stdenv.isDarwin ["MACOSX_DEPLOYMENT_TARGET=10.9"]
    ++
    [
      "FC=gfortran"
      # Note that clang is available through the stdenv on OSX and
      # thus is not an explicit dependency.
      "CC=${if stdenv.isDarwin then "clang" else "gcc"}"
      ''PREFIX="''$(out)"''
      "BINARY=${binary}"
      "USE_OPENMP=0"
      "USE_THREAD=0"
      "INTERFACE64=${if blas64 then "1" else "0"}"
    ];

  blas64 = if blas64Orig != null then blas64Orig else hasPrefix "x86_64" stdenv.system;

  meta = with stdenv.lib; {
    description = "Basic Linear Algebra Subprograms";
    license = licenses.bsd3;
    homepage = "https://github.com/xianyi/OpenBLAS";
    platforms = with platforms; unix;
    maintainers = with maintainers; [ ttuegel ];
  };
}
