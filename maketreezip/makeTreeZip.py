#!/usr/bin/python3
import os, sys, zipfile, optparse, zlib, fnmatch, time, tempfile, datetime
import unicodedata
'''
Add proper docstring here

TODO: assume sensible defaults if parameters not provided
i.e. assume current directory for zipping and for extraction
assume archive.zip as name or (dir).zip as name if no archive name provided
TODO: show progressbar while extracting, read comment about number of files, and calculate based on files extracted, if possible
    Add time taken to extract as well
TODO: refactor code into proper functions, rather than procedural code, especially the main body
TODO: fix usage to be accurate
TODO: use the unicode functions to skip files? 

'''
SUFFIXES = {1000: ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            1024: ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB']}

# Restores the timestamps of zipfile contents.
def RestoreTimestampsOfZipContents(zinfolist, extract_dir):
    for f in zinfolist:
        # path to this extracted f-item
        fullpath = os.path.join(extract_dir, f.filename)
        # still need to adjust the dt o/w item will have the current dt
        date_time = time.mktime(f.date_time + (0, 0, -1))
        # update dt
        os.utime(fullpath, (date_time, date_time))

def humanReadableByteCount(size, a_kilobyte_is_1024_bytes=True):
    '''Convert a file size to human-readable form.

    Keyword arguments:
    size -- file size in bytes
    a_kilobyte_is_1024_bytes -- if True (default), use multiples of 1024
                                if False, use multiples of 1000

    Returns: string
    from http://getpython3.com/diveintopython3/your-first-python-program.html#divingin
    '''
    if size < 0:
        raise ValueError('number must be non-negative')

    multiple = 1024 if a_kilobyte_is_1024_bytes else 1000
    for suffix in SUFFIXES[multiple]:
        if size < multiple:
            return '{0:.1f} {1}'.format(size, suffix)
        size = float(size) / multiple

    raise ValueError('number too large')

def zfAddNullFile(zf, arcname, date_time, extattr=0):
  """ Adapted from the method in zipfile """
  arcname = os.path.normpath(os.path.splitdrive(arcname)[1])
  arcname = arcname.lstrip(os.sep + (os.altsep or ""))
  zinfo = zipfile.ZipInfo(arcname, date_time)
  zinfo.external_attr = extattr
  zinfo.compress_type = zipfile.ZIP_STORED
  zinfo.file_size = 0
  zinfo.flag_bits = 0x00
  zinfo.header_offset = zf.fp.tell()    # Start of header bytes
  zf._writecheck(zinfo)
  zf._didModify = True
  zinfo.CRC = zlib.crc32(b"")
  zinfo.compress_size = 0
  zinfo.file_size = 0
  zf.fp.write(zinfo.FileHeader())
  zf.filelist.append(zinfo)
  zf.NameToInfo[zinfo.filename] = zinfo

def is_unicode_filename(filename):
  return any(ord(c) >= 0x7F for c in filename)

def cleanFilename(f):
  return unicodedata.normalize('NFKD',f).encode('ASCII','ignore').decode()

def printFilename(f, msg=None):
  if not options.quiet:
    if msg:
      print(msg, end=' ')
    
    try:
      print(f)
    except:
      print(f.encode("charmap", "replace"))

if __name__ == '__main__':
  usage = """%prog [options] <target-zip> <source-dir> [<source-dir...>]
    -m, --exclude_mask, Exclude mask
    -q, --quite, Quiet mode
    -e, --omit_empty, Omit empty directories
    -z, --rezip, Do not rezip the target to make it smaller
    -x, --extract, Extracts the zipfile and all zipfiles within it. 
    
    The <target-zip> will be overwritten if it exists. 
    This program will create a <target-zip> of all the filenames ONLY, no data from the files 
    (retaining directory structure) in the provided <source directories>. 
    
    The intent is to allow you to recreate a FILE & DIRECTORY structure in another location
    without all the content and data. 
  """

  optp=optparse.OptionParser(usage=usage)
  optp.add_option("-m", help="exclude mask", action="append", dest="exclude_mask", default=[])
  optp.add_option("-q", help="be quiet", action="store_true", dest="quiet", default=False)
  optp.add_option("-e", help="omit empty directories", action="store_true", dest="omit_empty", default=False)
  optp.add_option("-z", help="don't rezip the target to make it smaller", action="store_false", dest="rezip", default=True)
  optp.add_option("-x", help="Extracts the zipfile and all zipfiles within it.", action="store_true", dest="extract", default=False)
  optp.add_option("-d", help="Debug.", action="store_true", dest="debug", default=False)
  err=optp.error

  options, args = optp.parse_args()

  if len(args)<2:
    optp.print_usage()
    sys.exit(1)
  else:
    #Basic input validation
    # Check if file exists? Warn about overwriting
    target_zip = os.path.abspath(args[0])
    if not(target_zip.endswith(".zip")):
      target_zip += ".zip"
    if options.rezip:
      intermediate_zip = target_zip.replace(".zip","zip.zip") # should append zip rather than use zip extension, if no extension provided then?
    else:
      intermediate_zip = target_zip
    for source in args[1:]:
      try:
        source_dir=source#.decode("latin-1")
      except:
        print("Exception while trying to process directory: %s" % (source))
    if options.debug:
      print(target_zip)
      print(intermediate_zip)
      print(source_dir)

  # EXTRACT 
  if options.extract:
    """ Extracts the zipfile and all zipfiles in it larger than 0 bytes """
    try:
      zf=zipfile.ZipFile(target_zip, "r")
    except IOError as e:
      print(e)
      sys.exit(1)

    for info in zf.infolist():
      if info.filename.endswith("zip.zip") and info.file_size > 0:
        zf.extract(info)
        zf2=zipfile.ZipFile(info.filename,"r")
        zf2.extractall(source_dir)
        RestoreTimestampsOfZipContents(zf2.infolist,source_dir) #TO TEST
        zf2.close()
        os.remove(info.filename)
      else:
        zf.extractall(source_dir)
        RestoreTimestampsOfZipContents(zf.infolist,source_dir) #TO TEST
    zf.close()

    print("Files extracted successfuly to %s" % (source_dir))
    # for files in os.listdir(source_dir):
    #   if files.endswith(".zip"):
    #     zf=zipfile.ZipFile(files, "r")
    #     zf.extractall(source_dir)
    #     zf.close()
        
    sys.exit(0)

  # MAKE TREE ZIP
  zf=zipfile.ZipFile(intermediate_zip, "w")
  filecount = 0

  for sourceDir in args[1:]:
    try:
      sourceDir=sourceDir#.decode("latin-1")
      print("Processing directory: " + sourceDir)
    except Exception as e:
      print("Exception while trying to process directory: " + sourceDir)
      print(str(e))
    for dp, dn, fn in os.walk(sourceDir):
      if fn:
        for f in fn:
          f=os.path.join(dp, f)
          #f=f.encode('utf-8','surrogateescape').decode('utf-8','replace') #workaround for non printable characters
          # to overcome path limitations in windows: see https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247(v=vs.85).aspx#maxpath
          # or https://stackoverflow.com/questions/45041836/windowserror-error-3-the-system-cannot-find-the-path-specified-when-path-too
          #f="\\\\?\\" + os.path.join(dp, f)
          ok=True
          for xmask in options.exclude_mask:
            if fnmatch.fnmatch(f, xmask):
              ok=False
              break
          if ok:
            try:
              #workaround for filepaths greather than 260 characters see comment above
              #have to check if os is windows
              if len(f) >= 260 and os.name == 'nt':
                f = "\\\\?\\" + f
              mtime=time.localtime(os.stat(f).st_mtime)
            except ValueError:
              print("Error: Modified time out of range.")
              printFilename(f)
              print(os.stat(f).st_mtime)
            except FileNotFoundError as e:
              print("File not found, probably due to illegal filename characters")
              print(str(e))              
            except WindowsError as e:
              print("Error: Can't find file due to windows limitations.")
              print(str(e))
              #printFilename(f)
            finally:
              if mtime.tm_year < 1980: # to fix the time error in zipfiles, that timestamps can't be before 1980, mabye this bug is fixed?
                print("")
                print("File: " + f)
                print("Got incorrect modified date: " + time.strftime("%Y-%m-%d %H:%M:%S", mtime))
                mtime = datetime.datetime.fromisoformat("1980-01-01").timetuple()
                print("Using default: " + time.strftime("%Y-%m-%d %H:%M:%S", mtime))
              
            #zfAddNullFile(zf, f, (mtime.tm_year, mtime.tm_mon, mtime.tm_mday, mtime.tm_hour, mtime.tm_min, mtime.tm_sec))
            zf.writestr(zipfile.ZipInfo(f,date_time=mtime),"") #this doubles the size of the zipfile, i assume it's because of the duplicate local header.
            # have to find a better way
            filecount += 1
            if (filecount % 1000) == 0:
              sys.stdout.write("\r%d" % filecount)
              #sys.stdout.flush()
      elif not options.omit_empty:
        mtime=time.localtime(os.stat(dp).st_mtime)
        #printFilename(dp, "(empty directory)")
        zfAddNullFile(zf, dp, (mtime.tm_year, mtime.tm_mon, mtime.tm_mday, mtime.tm_hour, mtime.tm_min, mtime.tm_sec), 16)
  msg = b"Zip file created successfuly in %.2f seconds with %d files." % (time.process_time(), filecount)  
  zf.comment = msg
  zf.close()

  if options.rezip:
    #tf = tempfile.NamedTemporaryFile()
    zf=zipfile.ZipFile(target_zip, "w", zipfile.ZIP_DEFLATED)
    zf.write(intermediate_zip,arcname=os.path.basename(intermediate_zip))
    zf.comment = msg
    zf.close()
    os.remove(intermediate_zip)
    #os.rename(tf.name,target_zip)
  
  print("\nFinished.")
  print(target_zip + " " + humanReadableByteCount(os.stat(target_zip).st_size))
  print(msg.decode())
  """ 
  py2exe no longer works after python 3.4 
  have to use pyinstaller instead. 

The solution I used was to use PyInstaller as an alternative because Py2Exe stopped development at python 3.4 and will not work with newer versions.

C:/>pip install pyinstaller
C:/>pyinstaller yourprogram.py

This will create a subdirectory called dist with the yourprogram.exe contained in a folder called yourprogram.

Use -F to place all generated files in one executable file.

C:/>pyinstaller -F yourprogram

Use can use -w to if you want to remove console display for GUI's.

C:/>pyinstaller -w yourprogram.py

Putting it all togerther.

C:/>pyinstaller -w -F yourprogram.py

Read more about PyInstaller here.



Summarizing for Python3 former contribs: 
def update_progress(progress):
  print("\rProgress: [{0:50s}] {1:.1f}%".format('#' * int(progress * 50), progress*100), end="", flush=True), 
where workdone is a float between 0 and 1, e.g., workdone = parsed_dirs/total_dirs ??? khyox Dec 11 '14 at 12:35

   """