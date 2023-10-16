#!/bin/bash
app_info="Программа подключения клиента к домену ALDpro. \nАвтор данной программы Габидуллин Александр  © 2023. \nДля связи с автором по этой или другой программе писать на почту gabidullin.aleks@yandex.ru. \nТакже есть youtube-канал с более подробной инструкцией @XizhinaAdministratora"
internet_error="У вас проблемы с доступом к сайту dl.astralinux.ru. Проверьте настройку интернет соединения и правильность dns."
license="Продолжая установку ALDPro с помощью данной программы, Вы подтверждаете что приобрели лицензию и согласны с ее условиями. Автор программы не предоставляет лицензию на продукт."
reboot="Для корректной работы необходимо перезагрузить компьютер."

if ping -c 1 dl.astralinux.ru &> /dev/null; then
    echo "$app_info"
    echo "$license" 
    if id -nG | grep -qw "astra-admin"; then
        echo ok
    else 
        echo "Пользователь не принадлежит группе astra-admin. Необходимо зайди под пользователем с правами администратора."
        exit 1
    fi
        # Define the long options and short options
        OPTIONS=n:N:f:i:l:p:d:h
        LONGOPTIONS=name_client:,name_domain:,fqdn:,ipaddres:,login:,password:,passwd_dom:,help

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
-n|--name_client указывает имя клиента домена типа: client1
-N|--name_domain указывает имя домена типа: domain.test
-f|--fqdn указывает имя полное доменное имя клиента типа: client1.domain.test
-i|--ipaddres указывает статическией адрес вашего контроллера домена 10.10.10.10
-l|--login логин администратора домена ALDPro типа: login
-p|--password указывает пароль администратора локального
-d|--passwd_dom указывать пароль администратора домена ALDPro"
        name_dc=""
        name_domain=""
        fqdn=""
        ipaddres=""
        login=""  
        passwd=""  
        passwd_dom=""
        # Loop through the command line arguments
        while true; do
        case "$1" in
            -n|--name_client)
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
            -l|--login)
            login="$2"
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
    echo "$passwd" | sudo -Sv >/dev/null 2>&1
        if [ $? -eq 0 ]; then
        echo ok
        else
            echo "Неправильный пароль от sudo. Необходимо запустить скрипт повторно."
            exit 1
            # Добавьте здесь код, который должен выполниться, если пароль от sudo введен неправильно.
        fi
            version_astra=$(cat /etc/astra_version)
            version="1.7.4"
            version_old="У вас установлена версия астры  "$version_astra" и она будет обновлена до 1.7.4"
            version_new="У вас установлена версия астры  "$version_astra" и установка продолжиться дальше"
                if [ $version_astra != "$version" ]; then
                    echo "$version_old" 
                else
                    echo "$version_new" 
                fi
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
            #меняет файл hosts
            echo $passwd | sudo -S sed -i '/^127\.0\.0\.1/d' /etc/hosts 
            echo $passwd | sudo -S sed -i '/^127\.0\.1\.1/d' /etc/hosts
            echo $passwd | sudo -S bash -c "echo '127.0.0.1 localhost.localdomain localhost' >> /etc/hosts"
#            echo $passwd | sudo -S bash -c "echo '$ipaddres $fqdn $name_client' >> /etc/hosts"
            echo $passwd | sudo -S bash -c "echo '127.0.1.1 $name_client' >> /etc/hosts"
            #Добавляем приоритет
            echo $passwd | sudo -S bash -c "echo 'Package: *' >> /etc/apt/preferences.d/aldpro"
            echo $passwd | sudo -S bash -c 'echo Pin: release n=generic >> /etc/apt/preferences.d/aldpro'
            echo $passwd | sudo -S bash -c 'echo Pin-Priority: 900 >> /etc/apt/preferences.d/aldpro'
            # обновление системы
            echo $passwd | sudo -S apt update
            echo $passwd | sudo -S apt install astra-update -y
            echo $passwd | sudo -S astra-update -A -r -T
            echo $passwd | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -q -y aldpro-client
            exit_code=$?
            # Проверка кода завершения и отображение соответствующего сообщения
                if [ $exit_code -eq 0 ]; then
                    zenity --info --title="Успех" --text="Система успешно обновлена"
                else
                    zenity --error --title="Ошибка" --text="Ошибка при обновление системы."
                    exit 1
                fi
            #меняем resolf.conf
            echo $passwd | sudo -S bash -c "echo '# Generated by NetworkManager' > /etc/resolv.conf"
            echo $passwd | sudo -S bash -c "echo 'search $name_domain' >> /etc/resolv.conf" 
            echo $passwd | sudo -S bash -c "echo 'nameserver $dns' >> /etc/resolv.conf" 
            echo $passwd | sudo -S /opt/rbta/aldpro/client/bin/aldpro-client-installer -c "$name_domain" -u "$login" -p "$passwd_dom" -d "$name_client" -i -f
            exit_code=$?
            # Проверка кода завершения и отображение соответствующего сообщения
                if [ $exit_code -eq 0 ]; then
                    zenity --info --title="Успех" --text="Клиент успешно подключен"
                else
                    zenity --error --title="Ошибка" --text="Ошибка при подключению к домену"
                    exit 1
                fi
            echo "$reboot" 
else
    echo "$internet_error"
    exit 1
fi