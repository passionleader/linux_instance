[root@seongsu 0729]# cat ../MY/rvm.sh
#!/bin/bash

temp=$(virsh list --all | gawk '{print $2}' | grep -v Name)

for i in $temp
do
        echo -n "destroing $i"
        virsh destroy $i
        virsh undefine $i
        rm -f /cloud/${i}.qcow2

done
