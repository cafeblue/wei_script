#! /bin/bash

#space=`df -l /dev/sdb1|grep "sdb1" | perl -e '$aaaa = (split(/\s+/, <>))[3]; print $aaaa'`
space=`df |grep "11714559872" | perl -e '$aaaa = (split(/\s+/, <>))[3]; print $aaaa'`

if (( $space < 300000000 )) 
then
    mail -s "WARNING!!! spare space on sdb1 is less 300G!" ftian@berrygenomics.com blv@berrygenomics.com cysun@berrygenomics.com -c wangwei@berrygenomics.com < /home/wangw/space.txt 
fi
