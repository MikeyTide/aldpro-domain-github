#!/bin/bash
version_now=2.1
app_info="Программа установки AldPro. \nВо время установки будет произведена перезагрузка системы, необходимо будет опять зайти под администратором и ввести пароль. \nВерсия ALDPro: "$version_now". \nРазработчик: ГК Астра. \nАвтор данной программы Габидуллин Александр © 2023. \nДля связи с автором по этой или другой программе писать на почту gabidullin.aleks@yandex.ru. \nТакже есть youtube-канал с более подробной инструкцией @XizhinaAdministratora"
version_po="Версия программы 1.0.1. \n Данная версия поддерживает установку только из интернет репозитория. \nОна устанавливает ALDPro сразу с глобальным каталогом и модулем синхронизации "
app_info1="Введите второй раз пароль администратора для продолжения разварачивания ALDPro."
reboot_info="Сейчас произойдет перезагрузка. Послее нее необходимо будет опять войти под пользователем администратора с высокой целостностью."
file_path="/opt/aldpro"
error_lvl="Вы пытаетесь установить ALDPro на версию Astra Linux отличную от версии Смоленск."
internet_error="У вас проблемы с доступом к сайту dl.astralinux.ru. Проверьте настройку интернет соединения и правильность dns."
license="Продолжая установку ALDPro с помощью данной программы, Вы подтверждаете что приобрели лицензию и согласны с ее условиями. Автор программы не предоставляет лицензию на продукт."
if ping -c 1 dl.astralinux.ru &> /dev/null; then
    if [ -f "$file_path/small_fqdn" ]; then
        zenity --info --text="$app_info1" --height=300 --width=400
        passwd=$(zenity --forms --title="Пароль для администратора" \
            --text="Введите пароль администратора" \
            --add-password="Пароль")
        #проверка правильности введеного пароля sudo 
        echo "$passwd" | sudo -Sv >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo ok
            # Добавьте здесь код, который должен выполниться после успешного ввода пароля от sudo.
        else
            zenity --info --text="Неправильный пароль от sudo. Необходимо перезайти в сессию администратора и скрипт автоматом запуститься повторно"
            exit 1
            # Добавьте здесь код, который должен выполниться, если пароль от sudo введен неправильно.
        fi
        passwd_dom=$(zenity --forms --title="Пароль для администратора домена" \
            --text="Придумайте пароль для администратора домена" \
            --add-password="Пароль") 
        small_fqdn=$(cat $file_path/small_fqdn)
        big_fqdn=$(cat $file_path/big_fqdn)
        fqdn=$(cat $file_path/fqdn)
        ipaddres=$(cat $file_path/ipaddres)
        (
        # обновление системы
        echo $passwd | sudo -S apt update
        echo $passwd | sudo -S apt install astra-update -y
        echo $passwd | sudo -S astra-update -A -r -T
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            zenity --info --title="Успех" --text="Система успешно обновлена"
        else
            zenity --error --title="Ошибка" --text="Ошибка при обновление системы. Запустите скрипт повторно или обновите систему самостоятельно до версии 1.7.4."
            exit 1
        fi
        ) | zenity --progress --pulsate
        (
        echo $passwd | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -q -y aldpro-mp aldpro-gc aldpro-syncer
        echo $passwd | sudo -S sed -i 's/dns-nameservers 77.88.8.8/dns-nameservers 127.0.0.1/g' /etc/network/interfaces
        echo $passwd | sudo -S bash -c  "echo -e 'search $big_fqdn' > /etc/resolv.conf"
        echo $passwd | sudo -S bash -c  "echo -e 'nameserver 127.0.0.1' >> /etc/resolv.conf"
        echo $passwd | sudo -S aldpro-server-install -d "$big_fqdn" -n "$small_fqdn" -p "$passwd_dom" --ip "$ipaddres" --no-reboot --setup_syncer --setup_gc
        #выключить dnssec
        echo $passwd | sudo -S sed -i 's/dnssec-validation yes;/dnssec-validation no;/g' /etc/bind/ipa-options-ext.conf
        echo $passwd | sudo -S bash -c 'echo dnssec-enable no; >> /etc/bind/ipa-options-ext.conf'
        echo $passwd | sudo -S systemctl restart bind9-pkcs11
        exit_code=$?
        # Проверка кода завершения и отображение соответствующего сообщения
            if [ $exit_code -eq 0 ]; then
                zenity --info --title="Успех" --text="ALDPro успешно установлен!"
            else
                zenity --error --title="Ошибка" --text="Ошибка при установке ALDPro. Перезайдите в сессию администратора и скрипт попытается автоматически повторит попытку установки."
                exit 1
            fi
        ) | zenity --progress --pulsate
        installed="ALDPro был успешно установлен на ваш сервер. Для просмотра веб-панели перейдите в браузер по ссылке https://"$fqdn"\nДанные для входа логин: admin, пароль: Который вы указывали"
        $(zenity --info --text="$installed" --height=300 --width=400)
        firefox -new-tab https://"$fqdn"&
        echo $passwd | sudo -S rm -r /opt/aldpro
        echo $passwd | sudo -S rm /etc/xdg/autostart/aldpro.desktop
        echo $passwd | sudo -S rm /opt/aldpro.sh
    else
        $(zenity --info --text="$license" --height=300 --width=400)
        $(zenity --info --text="$version_po" --height=300 --width=400)
        $(zenity --info --text="$app_info" --height=300 --width=400)
        if id -nG | grep -qw "astra-admin"; then
            echo ok
        else 
            zenity --info --text="Пользователь не принадлежит группе astra-admin. Необходимо зайди под пользователем с правами администратора."
            exit 1
        fi
        passwd=$(zenity --forms --title="Пароль для администратора" \
            --text="Введите пароль администратора" \
            --add-password="Пароль")
        #проверка правильности введеного пароля sudo 
        echo "$passwd" | sudo -Sv >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                # Добавьте здесь код, который должен выполниться после успешного ввода пароля от sudo.
                lvl=$(echo "$passwd" | sudo -S astra-modeswitch get)
                    if [ $lvl != 2 ] ; then 
                        zenity --info --text="$error_lvl" --height=300 --width=400
                        else
                        form_data=$(zenity --forms --title="Введите данные" --text="Введите данные:" \
                                --add-entry="Введите имя контроллера домена имя типа: dc" \
                                --add-entry="Введите имя домена типа: domain.test" \
                                --add-entry="Введите имя полное доменное имя типа: dc.domain.test" \
                                --add-entry="Введите статический ip-address вашего будущего домена типа: 10.10.10.10" \
                                --add-entry="Введите маску подсети вашего будущего домена типа: 255.255.255.0" \
                                --add-password="Введите gateway сети вашего будущего домена типа: 10.10.10.1" )
                                # Разбиение строки с данными на отдельные переменные
                                small_fqdn=$(echo "$form_data" | awk -F '|' '{print $1}')
                                big_fqdn=$(echo "$form_data" | awk -F '|' '{print $2}')
                                fqdn=$(echo "$form_data" | awk -F '|' '{print $3}')
                                ipaddres=$(echo "$form_data" | awk -F '|' '{print $4}')
                                mask=$(echo "$form_data" | awk -F '|' '{print $5}')
                                gateway=$(echo "$form_data" | awk -F '|' '{print $6}')
                                #запись в файлы
                                echo $passwd | sudo -S bash -c "echo '$ipaddres' >> /opt/aldpro/ipaddres"
                                echo $passwd | sudo -S bash -c "echo '$small_fqdn' >> /opt/aldpro/small_fqdn"
                                echo $passwd | sudo -S bash -c "echo '$fqdn' >> /opt/aldpro/fqdn"
                                echo $passwd | sudo -S bash -c "echo '$big_fqdn' >> /opt/aldpro/big_fqdn"
                                version_astra=$(cat /etc/astra_version)
                                version="1.7.4"
                                version_old="У вас установлена версия астры "$version_astra" и она будет обновлена до 1.7.4"
                                version_new="У вас установлена версия астры "$version_astra" и установка продолжиться дальше"
                                    if [ "$version_astra" != "$version" ]; then
                                        zenity --info --text="$version_old" --height=300 --width=400
                                    else
                                        zenity --info --text="$version_new" --height=300 --width=400
                                    fi
                                (
                                #репы
                                echo $passwd | sudo -S bash -c "echo -e 'deb https://dl.astralinux.ru/aldpro/stable/repository-extended/ generic main' >> /etc/apt/sources.list.d/aldpro.list"
                                echo $passwd | sudo -S bash -c "echo -e 'deb https://dl.astralinux.ru/aldpro/stable/repository-main/ 2.1.0 main' >> /etc/apt/sources.list.d/aldpro.list" 
                                echo $passwd | sudo -S bash -c "echo -e 'deb http://dl.astralinux.ru/astra/frozen/1.7_x86-64/1.7.4/repository-extended 1.7_x86-64 main contrib non-free' >> /etc/apt/sources.list" 
                                echo $passwd | sudo -S bash -c "echo -e 'deb http://dl.astralinux.ru/astra/frozen/1.7_x86-64/1.7.4/repository-base 1.7_x86-64 main non-free contrib' >> /etc/apt/sources.list"
                                # установка сертификатов
                                echo $passwd | sudo -S apt update
                                echo $passwd | sudo -S apt install ca-certificates -y
                                #переименовываем тачку в домен
                                echo $passwd | sudo -S hostnamectl set-hostname $fqdn
                                #настройка hosts
                                echo $passwd | sudo -S sed -i '/^127\.0\.0\.1/d' /etc/hosts
                                echo $passwd | sudo -S sed -i '/^127\.0\.1\.1/d' /etc/hosts
                                echo $passwd | sudo -S bash -c "echo '127.0.0.1 localhost.localdomain localhost' >> /etc/hosts"
                                echo $passwd | sudo -S bash -c "echo '$ipaddres $fqdn $small_fqdn' >> /etc/hosts"
                                echo $passwd | sudo -S bash -c "echo '127.0.1.1 $small_fqdn' >> /etc/hosts"
                                # добавление в автозапуск
                                echo $passwd | sudo -S cp "$0" /opt/aldpro.sh 
                                echo $passwd | sudo -S chmod +x /opt/aldpro.sh
                                echo $passwd | sudo -S bash -c "echo -e '[Desktop Entry]
                    Type=Application
                    Categories=System;Utility;
                    Exec=/opt/aldpro.sh
                    Terminal=false
                    Icon=1cestart-8.3.18-1959.png
                    StartupNotify=true
                    Name=aldpro
                    Name[ru]=aldpro
                    Comment=dialog window
                    Comment[ru]=диалоговые окна
                    NoDisplay=false
                    Hidden=false' >> /etc/xdg/autostart/aldpro.desktop"
                                #приоритеты
                                echo $passwd | sudo -S bash -c "echo 'Package: *' >> /etc/apt/preferences.d/aldpro"
                                echo $passwd | sudo -S bash -c 'echo Pin: release n=generic >> /etc/apt/preferences.d/aldpro'
                                echo $passwd | sudo -S bash -c 'echo Pin-Priority: 900 >> /etc/apt/preferences.d/aldpro'
                                #выключаем нетворкманагер
                                echo $passwd | sudo -S sudo systemctl stop NetworkManager
                                echo $passwd | sudo -S sudo systemctl disable NetworkManager
                                echo $passwd | sudo -S sudo systemctl mask NetworkManager
                                #включаем нетворкинг
                                echo $passwd | sudo -S bash -c 'echo auto eth0 >> /etc/network/interfaces'
                                echo $passwd | sudo -S bash -c 'echo iface eth0 inet static >> /etc/network/interfaces'
                                echo $passwd | sudo -S bash -c "echo 'address $ipaddres' >> /etc/network/interfaces"
                                echo $passwd | sudo -S bash -c "echo 'netmask $mask' >> /etc/network/interfaces"
                                echo $passwd | sudo -S bash -c "echo 'gateway $gateway' >> /etc/network/interfaces"
                                echo $passwd | sudo -S bash -c 'echo dns-nameservers 77.88.8.8 >> /etc/network/interfaces'
                                echo $passwd | sudo -S bash -c "echo 'dns-search $big_fqdn' >> /etc/network/interfaces"
                                exit_code=$?
                                if [ $exit_code -eq 0 ]; then
                                    zenity --info --title="Успех" --text="Предварительная настройка прошла успешно."
                                else
                                    zenity --error --title="Ошибка" --text="Ошибка при предварительной настройке."
                                    exit 1
                                fi
                                ) | zenity --progress --pulsate
                                #перезагрузка для применения
                                zenity --info --text="$reboot_info" --height=300 --width=400
                                echo $passwd | sudo -S reboot     
                                fi
                                else
                                zenity --info --text="Неправильный пароль от sudo. Перезапустите скрипт."
                                exit 1
                                fi
                        fi
else
    zenity --info --text="$internet_error"

fi
