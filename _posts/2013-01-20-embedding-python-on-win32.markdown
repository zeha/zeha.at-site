---
layout: post
title: "Statically Embedding Python on Windows"
---

[superstatic](https://github.com/zeha/python-superstatic)
are the pre-made bits and bolts for statically embedding a Python
interpreter with your Windows application.

The standard solution for embedding Python on Windows is to
dynamically link with pythonNN.dll. That's quite like how standard Python
works on Windows. Check your install: Python.exe is 27KB in size.
Just enough to call into pythonNN.dll.

PythonNN.dll is large: 2.7MB, and it resides in `%SYSTEMROOT%\system32`.
These 2.7MB exclude all standard C extensions, as they live in seperate
PYD files.

While you can't really do anything about the code size, shipping a huge
number of files and even a DLL in system32 can be avoided: The superstatic
Makefile will produce a single `pythonembed.lib` file to link with your
application. It will include the Python interpreter, and most standard C
extension modules.


Building your app with superstatic
----------------------------------

Build your app with these flags:

    CFLAGS=/GF /MP4 /nologo /EHsc /Iopenssl-$(OPENSSL_V)\inc32 \
        /IPython-$(PYTHON_V)\Include /IPython-$(PYTHON_V)\PC \
        /DPy_BUILD_CORE /MD /W4 /O2
    LINKFLAGS=/MACHINE:X86 /RELEASE /LTCG
    LIBS=openssl-$(OPENSSL_V)\out32\libeay32.lib \
        openssl-$(OPENSSL_V)\out32\ssleay32.lib \
        Python-$(PYTHON_V)\PCbuild\pythonembed.lib ws2_32.lib

What you'll still need to provide is the Python standard library. The
interpreter looks for site.py and other files from the stdlib on startup,
and without them, things might not work the way you'd expect.

If you don't set up anything extra, your app will search for the stdlib
in a directory called `lib`, just like standard Python.

Dealing with the Standard Library
---------------------------------

The last thing to do, is to get rid of that `lib` directory, so you can
ship a single EXE binary to your customers. From here on, I'll
claim "it works", but you're on your own with the implementation.

What you can do is, before running any Python code (but after calling
Py_Initialize):

  * hook up the zipimporter
  * reset sys.path to a zip containing the stdlib

Resetting sys.path from C:

    std::string some_path = ...;
    PyObject *pSearchPathList = PyList_New(0);
    PyObject *pPath = PyString_FromString(some_path.c_str());
    PyList_Append(pSearchPathList, pPath);
    Py_DECREF(pPath);
    PySys_SetObject("path", pSearchPathList);
    Py_DECREF(pSearchPathList);

Now you're down to two files. YourApp.Exe and lib.zip.

Combining both files is now trivial.


Caveats
-------

If you look closely, you'll notice that `Makefile` deletes quite a few
C extension modules that either can't be built on Windows or need
third party libraries. This includes the bz2, *db, elementtree and tk
modules. The exception here is the ssl module, which needs OpenSSL,
but the Makefile takes care of compiling OpenSSL for you.



Recommended Reading
-------------------

The repository above has all the required bits and bolts, but I
recommend you read up on Embedding Python in general before
continuing here:

  * [Extending and Embedding the Python Interpreter](http://docs.python.org/2/extending/)
  * [Python/C API Reference Manual](http://docs.python.org/2/c-api/index.html)

Note that I've linked the Python 2 documentation. My superstatic
patch is for Python 2 as well. With some tweaking it applies to
Python 3.3 as well, but I haven't done any testing besides a compile
test yet.
