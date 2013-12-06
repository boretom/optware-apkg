optware-apkg
============

# Build Optware package for ASUSTOR NAS #

run `bin/apkg-create-package.sh --help` to see how to invoke the script.

Example: `bin/apkg-create-package.sh i386`. That will create the Optware package for the i386 based ASUSTOR NAS, like AS-20xT/TE and AS-30xT. The *.apk file will be copied to the current directory and has date/time added to it's name to prevent overwritting existing files.

The `source` directory contains all files needed for Optware's ipkg to run on i386 or x86_64 based ASUSTOR NAS'. That's basically a bootstrap for each of the two architectures plus some needed config files

# What the package installer will do: #

* creates a share 'Optware' on '/volume1'. If it exists it won't be touched
* installing the '/opt' stuff into /usr/local/AppCentral/optware and symlinks that dir to /opt
* adds ENV variable to /etc/profile to set /opt/{sbin,bin} include path
* for AS-20xT/TE & AS-30xT sets up to use two package feeds per default:
	* i686g25 feed : i686 compile with gblic 2.5
	* a local feed which is initially empty, for testing homebrew packages  
	  Feed url is file:///volume1/Optware/local-feed/asustor-i686/cross/unstable
* for AS-60xT sets up to use one package feed per default since I couldn't find any feed on the good 'ol internet:
* a local feed which is initially empty, for testing homebrew packages  
  Feed url is file:///volume1/Optware/local-feed/asustor-x86_64/cross/unstable

If you remove the package all the installed apps will be gone but not your homebrew packages in the local-feed.

### AS-60xT owners###
Since it's no fun to install a package manager without packages available I did compile some and put them [here](http://optware.kupper.org/asustor-x86_64/cross/unstable) on the web.  
To get them you have two options:
* copy them to the local-feed directory (use Firefox and DownThemAll). And it's important that the file 'Packages', 'Packages.gz' and 'Packages.filelist' are going to be there too since that's what ipkg is looking at
* set up a feed file in `/opt/etc/ipkg/`, eg. `/opt/etc/ipkg/asustor-x86_64-kupper-org-feed.conf` with only one line in it:  
````
src/gz asustor-x86_64 http://optware.kupper.org/asustor-x86_64/cross/unstable
````

### Precompiled packages ###
If you're looking for precompiled packages, you can find them in the [first post](http://forum.asustor.com/viewtopic.php?f=42&t=2416) of this topic on the ASUSTOR community forum
