{ stdenv, buildPythonPackage, fetchurl, twisted, dateutil, jinja2
, sqlalchemy , sqlalchemy_migrate
, enableDebugClient ? false, pygobject ? null, pyGtkGlade ? null
}:

# enableDebugClient enables "buildbot debugclient", a Gtk-based debug control
# panel. Its mostly for developers.

assert enableDebugClient -> pygobject != null && pyGtkGlade != null;

buildPythonPackage (rec {
  name = "buildbot-0.8.10";
  namePrefix = "";

  src = fetchurl {
    url = "https://pypi.python.org/packages/source/b/buildbot/${name}.tar.gz";
    sha256 = "1x5513mjvd3mwwadawk6v3ca2wh5mcmgnn5h9jhq1jw1plp4v5n4";
  };

  patchPhase =
    # The code insists on /usr/bin/tail, /usr/bin/make, etc.
    '' echo "patching erroneous absolute path references..."
       for i in $(find -name \*.py)
       do
         sed -i "$i" \
             -e "s|/usr/bin/python|$(type -P python)|g ; s|/usr/bin/||g"
       done
    '';

  buildInputs = [ ];

  propagatedBuildInputs =
    [ twisted dateutil jinja2 sqlalchemy sqlalchemy_migrate
    ] ++ stdenv.lib.optional enableDebugClient [ pygobject pyGtkGlade ];

  # What's up with this?! 'trial' should be 'test', no?
  #
  # running tests
  # usage: setup.py [global_opts] cmd1 [cmd1_opts] [cmd2 [cmd2_opts] ...]
  #    or: setup.py --help [cmd1 cmd2 ...]
  #    or: setup.py --help-commands
  #    or: setup.py cmd --help
  #
  # error: invalid command 'trial'
  doCheck = false;

  postInstall = ''
    mkdir -p "$out/share/man/man1"
    cp docs/buildbot.1 "$out/share/man/man1"
  '';

  meta = with stdenv.lib; {
    homepage = http://buildbot.net/;

    license = stdenv.lib.licenses.gpl2Plus;

    # Of course, we don't really need that on NixOS.  :-)
    description = "Continuous integration system that automates the build/test cycle";

    longDescription =
      '' The BuildBot is a system to automate the compile/test cycle
         required by most software projects to validate code changes.  By
         automatically rebuilding and testing the tree each time something
         has changed, build problems are pinpointed quickly, before other
         developers are inconvenienced by the failure.  The guilty
         developer can be identified and harassed without human
         intervention.  By running the builds on a variety of platforms,
         developers who do not have the facilities to test their changes
         everywhere before checkin will at least know shortly afterwards
         whether they have broken the build or not.  Warning counts, lint
         checks, image size, compile time, and other build parameters can
         be tracked over time, are more visible, and are therefore easier
         to improve.

         The overall goal is to reduce tree breakage and provide a platform
         to run tests or code-quality checks that are too annoying or
         pedantic for any human to waste their time with.  Developers get
         immediate (and potentially public) feedback about their changes,
         encouraging them to be more careful about testing before checking
         in code.
      '';

    maintainers = with maintainers; [ bjornfor ];
    platforms = platforms.all;
  };
})
