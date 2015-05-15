#! /bin/bash
cd ~ 
for ga_files in `ls BaseCall/GA/rsync/*.csv 2>/dev/null`
do
    new_dir=${ga_files/%.csv/}
    if [ -e `ls /share/data2/seq_dir/${new_dir##*/}/finished.txt` ]
    then
        continue
    fi

    mv $new_dir.* BaseCall/GA/info/
    /home/cafeblue/bin/info_update.pl /share/data2/seq_dir/${new_dir##*/} GA
	mutt -s "${new_dir##*/} finished..." jwang@berrygenomics.com jgzhang@berrygenomics.com shwang@berrygenomics.com yyan@berrygenomics.com hmzhu@berrygenomics.com mhwang@berrygenomics.com jsun@berrygenomics.com qingliu@berrygenomics.com -c ftian@berrygenomics.com < /home/wangw/qc.txt
done

for hi_files in `ls BaseCall/HiSeq/rsync/*.csv 2>/dev/null`
do
    new_dir=${hi_files/%.csv/}
    if [ -e `ls /share/data2/seq_dir/${new_dir##*/}/finished.txt` ]
    then
        continue
    fi

    mv $new_dir.* BaseCall/HiSeq/info/
    /home/cafeblue/bin/info_update.pl /share/data2/seq_dir/${new_dir##*/} HiSeq
	mutt -s "${new_dir##*/} finished..." jwang@berrygenomics.com jgzhang@berrygenomics.com shwang@berrygenomics.com yyan@berrygenomics.com hmzhu@berrygenomics.com mhwang@berrygenomics.com jsun@berrygenomics.com qingliu@berrygenomics.com -c ftian@berrygenomics.com < /home/wangw/qc.txt
done
