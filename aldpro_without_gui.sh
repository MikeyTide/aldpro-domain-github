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
    if [ -f "$file_path/name_dc" ]; then
        passwd=$(cat $file_path/passwd)
        #проверка правильности введеного пароля sudo 
        echo "$passwd" | sudo -Sv >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo ok
            # Добавьте здесь код, который должен выполниться после успешного ввода пароля от sudo.
        else
            echo "Неправильный пароль от sudo. Необходимо перезайти в сессию администратора и скрипт автоматом запуститься повторно"
            exit 1
            # Добавьте здесь код, который должен выполниться, если пароль от sudo введен неправильно.
        fi
        name_dc=$(cat $file_path/name_dc)
        name_domain=$(cat $file_path/name_domain)
        fqdn=$(cat $file_path/fqdn)
        ipaddres=$(cat $file_path/ipaddres)
        passwd_dom=$(cat $file_path/passwd_dom)
        # обновление системы
        echo $passwd | sudo -S apt update
        echo $passwd | sudo -S apt install astra-update -y
        echo $passwd | sudo -S astra-update -A -r -T
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            echo "Успех"
        else
            echo "Ошибка"
            exit 1
        fi
        echo $passwd | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -q -y aldpro-mp aldpro-gc aldpro-syncer
        echo $passwd | sudo -S sed -i 's/dns-nameservers 77.88.8.8/dns-nameservers 127.0.0.1/g' /etc/network/interfaces
        echo $passwd | sudo -S bash -c  "echo -e 'search $name_domain' > /etc/resolv.conf"
        echo $passwd | sudo -S bash -c  "echo -e 'nameserver 127.0.0.1' >> /etc/resolv.conf"
        echo $passwd | sudo -S aldpro-server-install -d "$name_domain" -n "$name_dc" -p "$passwd_dom" --ip "$ipaddres" --no-reboot --setup_syncer --setup_gc
        #выключить dnssec
        echo $passwd | sudo -S sed -i 's/dnssec-validation yes;/dnssec-validation no;/g' /etc/bind/ipa-options-ext.conf
        echo $passwd | sudo -S bash -c 'echo dnssec-enable no; >> /etc/bind/ipa-options-ext.conf'
        echo $passwd | sudo -S systemctl restart bind9-pkcs11
        exit_code=$?
        # Проверка кода завершения и отображение соответствующего сообщения
            if [ $exit_code -eq 0 ]; then
                echo "Успех"
            else
                echo "Ошибка" 
                exit 1
            fi
        echo "ALDPro был успешно установлен на ваш сервер. Для просмотра веб-панели перейдите в браузер по ссылке https://"$fqdn"\nДанные для входа логин: admin, пароль: Который вы указывали"
        firefox -new-tab https://"$fqdn"&
        echo $passwd | sudo -S rm -r /opt/aldpro
        echo $passwd | sudo -S rm /etc/xdg/autostart/aldpro.desktop
        echo $passwd | sudo -S rm /opt/aldpro.sh
    else
        if id -nG | grep -qw "astra-admin"; then
            echo ok
        else 
            echo "Пользователь не принадлежит группе astra-admin. Необходимо зайди под пользователем с правами администратора."
            exit 1
        fi
        # Define the long options and short options
        OPTIONS=n:N:f:i:m:g:p:d:h
        LONGOPTIONS=name_dc:,name_domain:,fqdn:,ipaddres:,mask:,gateway:,password:,passwd_dom:,help

        # Parse the command line arguments
        PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")

        # Check for getopt errors
        if [ $? -ne 0 ]; then
        exit 1
        fi
        # Evaluate the command line arguments
        eval set -- "$PARSED"

        # Set the default values for 
        help="Помощь по необходимым параметрам для корректной работы программы:
-n| --name_dc указывает имя вашего контроллера домена dc
-N|--name_domain указывает домен вашего контроллера domain.test
-f|--fqdn указывает полное доменное имя вашего контроллера домена dc.domain.test
-i|--ipaddres указывает статическией адрес вашего контроллера домена 10.10.10.10
-m|--mask указывает маску подсети в формета 255.255.255.0
-g|--gateway указывает адрес вашего шлюза 10.10.10.1
-p|--password указывает пароль администратора локального
-d|--passwd_dom указывать пароль для будущего администратора домена ALDPro"
        name_dc=""
        name_domain=""
        fqdn=""
        ipaddres=""
        mask=""
        gateway=""  
        passwd=""  
        passwd_dom=""
        # Loop through the command line arguments
        while true; do
        case "$1" in
            -n|--name_dc)
            name_dc="$2"
            shift 2
            ;;
            -N|--name_domain)
            name_domain="$2"
            shift 2
            ;;
            -f|--fqdn)
            fqdn="$2"
            shift 2
            ;;
            -i|--ipaddres)
            ipaddres="$2"
            shift 2
            ;;
            -m|--mask)
            mask="$2"
            shift 2
            ;;
            -g|--gateway)
            gateway="$2"
            shift 2
            ;;
            -p|--password)
            passwd="$2"
            shift 2
            ;;
            -d|--passwd_dom)
            passwd_dom="$2"
            shift 2
            ;;
            -h|--help)
            echo "$help"
            exit 1
            ;;                                    
            --)
            shift
            break
            ;;
            *)
            echo "Invalid option: $1"
            exit 1
            ;;
        esac
        done
        #проверка правильности введеного пароля sudo 
        echo "$passwd" | sudo -Sv >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                # Добавьте здесь код, который должен выполниться после успешного ввода пароля от sudo.
                lvl=$(echo "$passwd" | sudo -S astra-modeswitch get)
                    if [ $lvl != 2 ] ; then 
                        echo $error_lvl
                        else
                                #запись в файлы
                                echo $passwd | sudo -S mkdir /opt/aldpro
                                echo $passwd | sudo -S bash -c "echo '$ipaddres' >> /opt/aldpro/ipaddres"
                                echo $passwd | sudo -S bash -c "echo '$name_dc' >> /opt/aldpro/name_dc"
                                echo $passwd | sudo -S bash -c "echo '$fqdn' >> /opt/aldpro/fqdn"
                                echo $passwd | sudo -S bash -c "echo '$name_domain' >> /opt/aldpro/name_domain"
                                echo $passwd | sudo -S bash -c "echo '$passwd_dom' >> /opt/aldpro/passwd_dom"
                                echo $passwd | sudo -S bash -c "echo '$passwd' >> /opt/aldpro/passwd"
                                version_astra=$(cat /etc/astra_version)
                                version="1.7.4"
                                version_old="У вас установлена версия астры "$version_astra" и она будет обновлена до 1.7.4"
                                version_new="У вас установлена версия астры "$version_astra" и установка продолжиться дальше"
                                    if [ "$version_astra" != "$version" ]; then
                                        echo "$version_old"
                                    else
                                        echo "$version_new"
                                    fi
                                #репы
                                echo $passwd | sudo -S bash -c "echo -e 'deb https://dl.astralinux.ru/aldpro/stable/repository-extended/ generic main' >> /etc/apt/sources.list.d/aldpro.list"
                                echo $passwd | sudo -S bash -c "echo -e 'deb https://dl.astralinux.ru/aldpro/stable/repository-main/ 2.1.0 main' >> /etc/apt/sources.list.d/aldpro.list"
                                echo $passwd | sudo -S bash -c "echo -e 'deb http://dl.astralinux.ru/astra/frozen/1.7_x86-64/1.7.4/repository-extended 1.7_x86-64 main contrib non-free' > /etc/apt/sources.list" 
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
                                echo $passwd | sudo -S bash -c "echo '$ipaddres $fqdn $name_dc' >> /etc/hosts"
                                echo $passwd | sudo -S bash -c "echo '127.0.1.1 $name_dc' >> /etc/hosts"
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
                                echo $passwd | sudo -S bash -c "echo 'dns-search $name_domain' >> /etc/network/interfaces"
                                exit_code=$?
                                if [ $exit_code -eq 0 ]; then
                                    echo "Предварительная настройка прошла успешно."
                                else
                                    echo "Ошибка при предварительной настройке."
                                    exit 1
                                fi
                                #перезагрузка для применения
                                echo "$reboot_info"
                                echo $passwd | sudo -S reboot     
                                fi
                                else
                                echo "Неправильный пароль от sudo. Перезапустите скрипт."
                                exit 1
                                fi
                        fi
else
    echo "$internet_error"

fi
