#!/usr/bin/python
import os, sys, zipfile, optparse, zlib, fnmatch, time, tempfile, time

SUFFIXES = {1000: ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            1024: ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB']}

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
  zinfo.compress_type = zf.compression
  zinfo.file_size = 0
  zinfo.flag_bits = 0x00
  zinfo.header_offset = zf.fp.tell()    # Start of header bytes
  zf._writecheck(zinfo)
  zf._didModify = True
  zinfo.CRC = CRC = zlib.crc32("")
  zinfo.compress_size = 0
  zinfo.file_size = 0
  zf.fp.write(zinfo.FileHeader())
  zf.filelist.append(zinfo)
  zf.NameToInfo[zinfo.filename] = zinfo
  
def printFilename(f, msg=None):
  if not options.quiet:
    if msg:
      print msg,
    
    try:
      print f
    except:
      print f.encode("charmap", "replace")

if __name__ == '__main__':
  start_time = time.clock()
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
    if options.rezip:
      intermediate_zip = target_zip.replace(".zip","zip.zip")
    else:
      intermediate_zip = target_zip
    for source in args[1:]:
      try:
        source_dir=source.decode("latin-1")
      except:
        print "Exception while trying to process directory: %s" % (source)
    if options.debug:
      print target_zip
      print intermediate_zip
      print source_dir

  # EXTRACT 
  if options.extract:
    """ Extracts the zipfile and all zipfiles in it larger than 0 bytes """
    try:
      zf=zipfile.ZipFile(target_zip, "r")
    except IOError, e:
      print e
      sys.exit(1)

    for info in zf.infolist():
      if info.filename.endswith("zip.zip") and info.file_size > 0:
        zf.extract(info)
        zf2=zipfile.ZipFile(info.filename,"r")
        zf2.extractall(source_dir)
        zf2.close()
        os.remove(info.filename)
    zf.close()

    print "Files extracted successfuly to %s" % (source_dir)
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
      sourceDir=sourceDir.decode("latin-1")
    except:
      print sourceDir
      print "Exception while trying to process directory"
    for dp, dn, fn in os.walk(sourceDir):
      if fn:
        for f in fn:
          #f=os.path.join(dp, f)
          # to overcome path limitations in windows: see https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247(v=vs.85).aspx#maxpath
          # or https://stackoverflow.com/questions/45041836/windowserror-error-3-the-system-cannot-find-the-path-specified-when-path-too
          f="\\\\?\\" + os.path.join(dp, f)
          ok=True
          for xmask in options.exclude_mask:
            if fnmatch.fnmatch(f, xmask):
              ok=False
              break
          if ok:
            try:
              mtime=time.localtime(os.stat(f).st_mtime)
            except ValueError:
              print "Error: Modified time out of range."
              printFilename(f)
              print os.stat(f).st_mtime
              mtime=time.localtime(0) #set time to unix epoch 0 = 'Thu Jan 01 07:00:00 1970'
            except WindowsError:
              print "Error: Can't find file due to windows limitations."
              printFilename(f)
              mtime=time.localtime(0) #set time to unix epoch 0 = 'Thu Jan 01 07:00:00 1970'
              
            zfAddNullFile(zf, f, (mtime.tm_year, mtime.tm_mon, mtime.tm_mday, mtime.tm_hour, mtime.tm_min, mtime.tm_sec))
            filecount += 1
      elif not options.omit_empty:
        mtime=time.localtime(os.stat(dp).st_mtime)
        #printFilename(dp, "(empty directory)")
        zfAddNullFile(zf, dp, (mtime.tm_year, mtime.tm_mon, mtime.tm_mday, mtime.tm_hour, mtime.tm_min, mtime.tm_sec), 16)
  msg = "Zip file created successfuly in %.2f seconds with %d files." % (time.clock()-start_time, filecount)  
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
  
  print msg
  print target_zip + " " + humanReadableByteCount(os.stat(target_zip).st_size)
  