#!/bin/bash

temp=$(mktemp -t test.XXX)      # 함수 내에서 결과를 파일로 저장
temp2=$(mktemp -t test.XXX)
dialogLS=$(mktemp -t test.XXX)
ans=$(mktemp -t test.XXX)       # 메뉴에서 선택한 번호를 담음
image=$(mktemp -t test.XXX)     # 템플릿 이미지를 담음
vmname=$(mktemp -t test.XXX)    # 가상 머신의 이름을 담음
flavor=$(mktemp -t test.XXX)    # CPU/RAM 세트인 flavor 정보를 담음

# 함수 선언
# # Virtual Machine의 List 출력
vmlist(){
        virsh list --all > $temp
        dialog --textbox $temp 20 50
}
# # 가상 네트워크 리스트 출력
vmnetlist(){
        virsh net-list --all > $temp
        dialog --textbox $temp 20 50
}
# # 가상 머신 삭제
#for i in $(명령어) ; do [반복할 작업] ; done
deletion(){
        virsh list --all > $temp
        vmls=$(cat $temp | grep -v "Name" | gawk '{print $2}')

        echo "" > $dialogLS
        for i in $vmls; do
                echo "$i 'instance' OFF" >> $dialogLS
        done
        dialogs=$(cat $dialogLS)
        dialog --title "인스턴스 제거" --radiolist "제거할 인스턴스 선택" 20 50 0 $dialogs 2> $temp2
        del=$(cat $temp2)
        #temp=$(cat $temp)
        #echo $temp
        virsh destroy $del
        virsh undefine ${del} --remove-all-storage

}
# # 가상 머신 생성
vmcreation(){
        dialog --title "이미지 선택" --radiolist "베이스 이미지를 선택하시오" 20 70 8 "CentOS7" "CentOS 2003 base image" ON "Ubuntu" "Ubuntu 2004 base image" OFF "RHEL" "Redhat enterprise Linux 8.0" OFF 2> $image

        vmimage=$(cat $image)
        case $vmimage in
        CentOS7)
                os=/cloud/CentOS7-Base.qcow2 ;;
        Ubuntu)
                os=/cloud/Ubuntu20-Base.qcow2 ;;
        RHEL)
                os=/cloud/RHEL-Base.qcow2 ;;
        *)
                dialog --msgbox "잘못 선택했습니다" 10 40 ;;
        esac

        # OS 선택 결과에 따라 정상처리라면 인스턴스 이름 입력하기로 이동시킴
        if [ $? -eq 0 ]
        then
                dialog --title "인스턴스이름" --inputbox "인스턴스의 이름을 입력하시오:" 10 50 2> $vmname

                # 선택된 이름 이용해서 BASE 이미지로부터 새로운 볼륨 생성
                name=$(cat $vmname)
                cp $os /cloud/${name}.qcow2

                # 종료 코드가 0(ok)인 경우 flavor 선택으로 이동
                if [ $? -eq 0 ]
                then
                        dialog --title "스펙 선택" --radiolist "필요한 자원을 선택" 15 50 5 "m1.small" "1 vCPU, 1GB RAM" ON "m1.medium" "2 vCPU, 2GB RAM" OFF "m1.large" "4 vCPU, 8GB RAM" OFF 2> $flavor

                        # flavor에 따라 변수에 CPU, RAM 사이즈 입력
                        spec=$(cat $flavor)
                        case $spec in
                        m1.small)
                                vcpus="1"
                                ram="1024"
                                dialog --msgbox "CPU: ${vcpus}cores, RAM: ${ram}MB" 10 50 ;;

                        m1.medium)
                                vcpus="2"
                                ram="2048"
                                dialog --msgbox "CPU: ${vcpus}cores, RAM: ${ram}MB" 10 50 ;;

                        m1.large)
                                vcpus="4"
                                ram="8192"
                                dialog --msgbox "CPU: ${vcpus}cores, RAM: ${ram}MB" 10 50 ;;

                        esac

                        # 종료코드가 0(정상)인 경우 설치 진행
                        if [ $? -eq 0 ]
                        then
                                virt-install --name $name --vcpus $vcpus --ram $ram --disk /cloud/${name}.qcow2 --import --network network:default,model=virtio --os-type linux --noautoconsole > /dev/null
                        fi
                        dialog --msgbox "설치가 시작되었습니다" 10 50
                fi

        fi

}



# 메인 코드
while [ 1 ]
do
        # # 메인 메뉴 출력
        dialog --menu "KVM 관리 시스템" 20 40 8 1 "가상머신리스트" 2 "가상네트워크리스트" 3 "가상머신생성" 4 "가상머신제거" 0 "종료" 2> $ans

        # # 종료 코드 확인, cancel이면 종료함
        if [ $? -eq 1 ]
        then
                break
        fi

        # # 선택에 따른 실행
        selection=$(cat $ans)
        case $selection in
        1)
                vmlist ;;
        2)
                vmnetlist ;;
        3)
                vmcreation ;;
        4)
                deletion ;;
        0)
                break ;;
        *)
                dialog --msgbox "잘못된 번호 선택됨" 10 40
        esac
done

# 종료 전 임시파일 제거
rm -rf $temp 2> /dev/null
rm -rf $dialogLS 2> /dev/null
rm -rf $ans 2> /dev/null
rm -rf $image 2> /dev/null
rm -rf $vmnet 2> /dev/null
rm -rf $flavor 2> /dev/null