__all__ = ("ffmpeg", "ffmpeg_version")

from functools import lru_cache as _lru_cache
import importlib.resources as _resources
import os as _os
from platform import machine as _machine
from struct import calcsize as _calcsize
import subprocess as _subprocess
import sys as _sys

def _popen_kwargs(prevent_sigint = False):
	startupinfo = None
	if _sys.platform.startswith("win"):
		startupinfo = _subprocess.STARTUPINFO()
		startupinfo.dwFlags |= _subprocess.STARTF_USESHOWWINDOW
	return {"startupinfo": startupinfo}

def _is_valid_exe(exe):
	cmd = [exe, "-version"]
	try:
		with open(_os.devnull, "w") as null:
			_subprocess.check_call(
				(exe, "-version"), stdout = null,
				stderr = _subprocess.STDOUT,
				**_popen_kwargs()
			)
		return True
	except (OSError, ValueError, _subprocess.CalledProcessError):
		return False

def _get_platform():
    bits = _calcsize("P") * 8
    if _sys.platform.startswith("linux"):
        architecture = _machine()
        if architecture == "aarch64":
            return "linuxaarch64"
        return "linux{}".format(bits)
    elif _sys.platform.startswith("freebsd"):
        return "freebsd{}".format(bits)
    elif _sys.platform.startswith("win"):
        return "win{}".format(bits)
    elif _sys.platform.startswith("cygwin"):
        return "win{}".format(bits)
    elif _sys.platform.startswith("darwin"):
        return "osx{}".format(bits)
    else:  # pragma: no cover
        return None

def _get_bin_dir():
	if _sys.version_info < (3, 9):
		ctx = _resources.path("xdcheckin_ffmpeg.bin", "__init__.py")
	else:
		ctx = _resources.as_file(_resources.files(
			"xdcheckin_ffmpeg.bin") / "__init__.py"
		)
	with ctx as path:
		pass
	return str(path.parent)

@_lru_cache()
def ffmpeg():
	"""Get the path of the FFmpeg executable.

	:return: Path string.
	"""
	bin = _get_bin_dir()
	for b in ("ffmpeg", "ffmpeg.exe"):
		exe = _os.path.join(bin, b)
		if exe and _os.path.isfile(exe) and _is_valid_exe(exe):
			return exe
	plat = _get_platform()
	if plat.startswith("win"):
		exe = _os.path.join(_sys.prefix, "Library", "bin", "ffmpeg.exe")
	else:
		exe = _os.path.join(_sys.prefix, "bin", "ffmpeg")
	if exe and _os.path.isfile(exe) and _is_valid_exe(exe):
		return exe
	exe = "ffmpeg"
	if _is_valid_exe(exe):
		return exe
	return None

@_lru_cache()
def ffmpeg_version():
	"""Get the version of the FFmpeg executable.

	:return: Version string.
	"""
	exe = ffmpeg()
	if not exe:
		return None
	line = _subprocess.check_output(
		[exe, "-version"], **_popen_kwargs()
	).split(b"\n", 1)[0]
	line = line.decode(errors = "ignore").strip()
	version = line.split("version", 1)[-1].lstrip().split(" ", 1)[0].strip()
	return version
