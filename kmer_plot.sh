#! /bin/bash
echo "set terminal png nocrop size 1280,1025" > tmp.gp
echo "set format y '10^(%.0f)'" >> tmp.gp
echo "set title 'Kmer Distrbution'" >> tmp.gp
echo "set xlabel 'multiplicity'" >> tmp.gp
echo "set ylabel 'Number of distict K-mers with given multiplicity'" >> tmp.gp
echo "plot  \"$1\" using 1:(\$2 < 1 ? 1 : log10(\$2)) title \"bezier_19\" smooth bezier, \"$2\" using 1:(\$2 < 1 ? 1 : log10(\$2)) title \"bezier_18\" smooth bezier, \"$3\" using 1:(\$2 < 1 ? 1 : log10(\$2)) title \"bezier_17\" smooth bezier, \"$4\" using 1:(\$2 < 1 ? 1 : log10(\$2)) title \"bezier_16\" smooth bezier;" >> tmp.gp
gnuplot < tmp.gp > $5
