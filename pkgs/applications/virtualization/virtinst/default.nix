{ stdenv, fetchurl, pythonPackages, intltool, libxml2Python, curl, libvirt }:

with stdenv.lib;

let version = "0.600.4"; in

stdenv.mkDerivation rec {
  name = "virtinst-${version}";

  src = fetchurl {
    url = "http://virt-manager.org/download/sources/virtinst/virtinst-${version}.tar.gz";
    sha256 = "175laiy49dni8hzi0cn14bbsdsigvgr9h6d9z2bcvbpa29spldvf";
  };

  pythonPath = with pythonPackages;
    [ setuptools eventlet greenlet gflags netaddr carrot routes
      PasteDeploy m2crypto ipy twisted
      distutils_extra simplejson readline glanceclient cheetah lockfile httplib2
      # !!! should libvirt be a build-time dependency?  Note that
      # libxml2Python is a dependency of libvirt.py.
      pythonPackages.libvirt libxml2Python urlgrabber
    ];

  buildInputs =
    [ pythonPackages.python
      pythonPackages.wrapPython
      pythonPackages.mox
      intltool
    ] ++ pythonPath;

  buildPhase = "python setup.py build";

  # virsh is a hard dependency as the tool is useless without it.
  # virt-viewer on the other hand is not a hard dependency, and is
  # invoked with execvp, so it doesn't need to have a canonical path
  # anyway.
  installPhase =
    ''
       python setup.py install --prefix="$out";
       substituteInPlace "$out/bin/virt-install" \
          --replace "/usr/bin/virsh" ${libvirt}/bin/virsh \
          --replace "/usr/bin/virt-viewer" "virt-viewer"
       wrapPythonPrograms
    '';

  meta = {
    homepage = http://virt-manager.org;
    license = stdenv.lib.licenses.gpl2Plus;
    maintainers = with stdenv.lib.maintainers; [qknight];
    description = "Command line tool which provides an easy way to provision operating systems into virtual machines";
  };
}
