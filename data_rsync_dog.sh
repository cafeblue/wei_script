#! /bin/bash 

for ga_files in `ls ~/BaseCall/GA/gerald/*.csv 2> /dev/null`
do
    new_dir=${ga_files/%.csv/}
    if [ ! -e /share/data1/GAdata/Runs/${new_dir##*/}/Data/Intensities/BaseCalls/Demultiplexed/finished.txt ] 
    then
        continue
    fi

    cd /share/data2/seq_dir/
    mkdir ${new_dir##*/}
    mv $new_dir.* /home/wangw/BaseCall/GA/rsync/
    cd ${new_dir##*/}
    ssh solexa@nas-0-0 "echo ${new_dir##*/} >> /home/solexa/.folder"
    /home/wangw/my_script/data_rsync_GA.pl
    ifpe=`grep "IsPairedEndRun" reports/Status.xml`
	mkdir /tmp/${new_dir##*/}
	for pngs in `ls /share/data2/seq_dir/${new_dir##*/}/0??/*_clean_fastqc/Images/per_base_quality.png`
	do
	    cp $pngs /tmp/${new_dir##*/}
		pngs=`echo $pngs | perl -e '$dir = <> ; @sp = split(/\//, $dir); $out = "$sp[5]_"; $out .= substr $sp[6], 0, 5; print $out;'`
		mv /tmp/${new_dir##*/}/per_base_quality.png /tmp/${new_dir##*/}/$pngs.png
	done
	for html in `ls /share/data2/seq_dir/${new_dir##*/}/0??/Summary.htm`
	do 
	    cp $html /tmp/${new_dir##*/}
        html=`echo $html | perl -e '$id= <> ; @sp = split(/\//, $id); print $sp[5];'`
		mv /tmp/${new_dir##*/}/Summary.htm /tmp/${new_dir##*/}/Summary_$html.htm
	done
    lftp -c "open -u htmlfile,htmlfile 192.168.4.241; mirror -R /tmp/${new_dir##*/}"
    /home/wangw/my_script/info_update.pl /share/data2/seq_dir/${new_dir##*/} GA "$ifpe"
	mail -s "${new_dir##*/} finished, please check the LIMS server..." yyren@berrygenomics.com jwang@berrygenomics.com jgzhang@berrygenomics.com shwang@berrygenomics.com yyan@berrygenomics.com hmzhu@berrygenomics.com mhwang@berrygenomics.com jsun@berrygenomics.com qingliu@berrygenomics.com -c ftian@berrygenomics.com wangwei@berrygenomics.com < /home/wangw/qc.txt
done

for hi_files in `ls ~/BaseCall/HiSeq/gerald/*.csv 2> /dev/null`
do 
    new_dir=${hi_files/%.csv/}
    if [ ! -e /share/data1/Hisdata/Runs/${new_dir##*/}/Unaligned/finished.txt ] 
    then
        continue
    fi

    cd /share/data2/seq_dir/
    mv $hi_files /home/wangw/BaseCall/HiSeq/rsync/
    mkdir  ${new_dir##*/}
    cd ${new_dir##*/}
    ssh solexa@nas-0-0 "echo ${new_dir##*/} >> /home/solexa/.folder"
    /home/wangw/my_script/data_rsync_HiSeq.pl
    ifpe=`grep "IsPairedEndRun" reports/Status.xml`
    mkdir /tmp/${new_dir##*/}
	for pngs in `ls ./*_001_clean_fastqc/Images/per_base_quality.png`
	do
	    cp $pngs /tmp/${new_dir##*/}/${pngs//_001_clean_fastqc\/Images\/per/}
	done
	cp Basecall_Stats_*/Demultiplex_Stats.htm /tmp/${new_dir##*/}
    lftp -c "open -u htmlfile,htmlfile 192.168.4.241; mirror -R /tmp/${new_dir##*/}"
    /home/wangw/my_script/info_update.pl /share/data2/seq_dir/${new_dir##*/} HiSeq "$ifpe" 
	mail -s "${new_dir##*/} finished, please check the LIMS server..." yyren@berrygenomics.com jwang@berrygenomics.com shwang@berrygenomics.com jgzhang@berrygenomics.com yyan@berrygenomics.com hmzhu@berrygenomics.com mhwang@berrygenomics.com jsun@berrygenomics.com qingliu@berrygenomics.com -c ftian@berrygenomics.com wangwei@berrygenomics.com < /home/wangw/qc.txt
done
