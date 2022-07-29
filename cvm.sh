[root@seongsu 0729]# cat ../MY/cvm.sh
#!/bin/bash

clear
echo -e "\t\t\t인스턴스 생성 프로그램 "
echo
echo "설치할 이미지를 선택하세요"
echo "1. CentOS 7"
echo "2. Ubuntu 18.04"
echo
echo -n "이미지 선택 : "
read name

if [ -z $name ]
then
        echo "이미지를 선택하지 않았습니다. 프로그램이 종료됩니다"
        exit
elif [ $name -eq 1 ]
then
        name="CentOS7-Base.qcow2"
elif [ $name -eq 2 ]
then
        name="Ubuntu1804.qcow2"
else
        echo "잘못된 번호를 선택했습니다. 프로그램이 종료됩니다"
        exit
fi

echo
echo -n "인스턴스 이름 입력 : "
read instancename
echo
echo -n "설치할 인스턴스의 개수를 선택하세요(1~4): "
read nums
echo
echo -n "CPU 개수 선택(1~4) : "
read vcpus
echo
echo -n "메모리 사이즈 선택(1~4GB) : "
read tempmem
ram=$(expr $tempmem \* 1024 )

echo
echo "설치가 진행됩니다"


hosts=$(hostname)

# 프로그램 설치 시작
for (( i=1; i<=${nums}; i++ ))
do
        cp /cloud/$name /cloud/${instancename}${i}.qcow2

        virt-install --name ${instancename}${i} --vcpus $vcpus --ram $ram --network network:default,model=virtio --disk /cloud/${instancename}${i}.qcow2 --import --noautoconsole > /dev/null
done

#확인
virsh list --all
echo
echo "결과를 준비중입니다. 잠시만요."
sleep 60

# IP 주소, CPU 사용량 알려주기
echo "[결과 안내]"
for (( i=1; i<=${nums}; i++ ))
do
        # IP 주소
        myip=$(virsh domifaddr ${instancename}${i} | grep -v Name | gawk '{print $4}' | sed '/^$/d' |gawk -F/ '{print $1}')
        echo "${instancename}${i} 의 IP 주소: ${myip}"

        # CPU
        mycpu=$(virt-top -d 2 --end-time +3 --stream | grep ${instancename}${i} | tail -1 | gawk '{print $7}')
        echo "${instancename}${i} 의 CPU 상태: ${mycpu}"

        # DB에 입력하기
        mysql -h192.168.1.199 -utestuser -ptest123 -e "use mylab; insert into instance values ( $RANDOM, '${instancename}${i}', '$myip', $vcpus, $tempmem, '$hosts', $mycpu );"

done
