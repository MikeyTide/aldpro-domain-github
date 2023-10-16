#!/bin/bash
app_info="Программа подключения клиента к домену ALDpro. \nАвтор данной программы Габидуллин Александр  © 2023. \nДля связи с автором по этой или другой программе писать на почту gabidullin.aleks@yandex.ru. \nТакже есть youtube-канал с более подробной инструкцией @XizhinaAdministratora"
internet_error="У вас проблемы с доступом к сайту dl.astralinux.ru. Проверьте настройку интернет соединения и правильность dns."
license="Продолжая установку ALDPro с помощью данной программы, Вы подтверждаете что приобрели лицензию и согласны с ее условиями. Автор программы не предоставляет лицензию на продукт."
reboot="Для корректной работы необходимо перезагрузить компьютер."
error_lvl="Вы пытаетесь установить ALDPro на версию Astra Linux отличную от версии Смоленск."

if ping -c 1 dl.astralinux.ru &> /dev/null; then
    zenity --info --text="$app_info" --height=200 --width=200
    zenity --info --text="$license" --height=200 --width=200
    if id -nG | grep -qw "astra-admin"; then
        echo ok
    else 
        zenity --info --text="Пользователь не принадлежит группе astra-admin. Необходимо зайди под пользователем с правами администратора."
        exit 1
    fi
    passwd=$(zenity --forms --title="Пароль для администратора" \
        --text="Введите пароль администратора" \
        --add-password="Пароль")
    echo "$passwd" | sudo -Sv >/dev/null 2>&1
        if [ $? -eq 0 ]; then
        echo ok
        else
            zenity --info --text="Неправильный пароль от sudo. Необходимо запустить скрипт повторно."
            exit 1
            # Добавьте здесь код, который должен выполниться, если пароль от sudo введен неправильно.
        fi
    lvl=$(echo "$passwd" | sudo -S astra-modeswitch get)
        if [ $lvl != 2 ] ; then 
            zenity --info --text="$error_lvl" --height=200 --width=200
        else
        form_data=$(zenity --forms --title="Введите данные" --text="Введите данные:" \
            --add-entry="Введите имя клиента домена типа: client1" \
            --add-entry="Введите имя домена типа: domain.test" \
            --add-entry="Введите имя полное доменное имя клиента типа: client1.domain.test" \
            --add-entry="Введите ip адрес вышего контроллера домена ALDPro: 10.10.10.10" \
            --add-entry="Введите логин администратора домена ALDPro типа: admin" \
            --add-password="Введите пароль администратора домена $admin ALDPro: Password123" )
            # Разбиение строки с данными на отдельные переменные
            small_fqdn=$(echo "$form_data" | awk -F '|' '{print $1}')
            big_fqdn=$(echo "$form_data" | awk -F '|' '{print $2}')
            fqdn=$(echo "$form_data" | awk -F '|' '{print $3}')
            dns=$(echo "$form_data" | awk -F '|' '{print $4}')
            admin=$(echo "$form_data" | awk -F '|' '{print $5}')
            pass_domain=$(echo "$form_data" | awk -F '|' '{print $6}')
            version_astra=$(cat /etc/astra_version)
            version="1.7.4"
            version_old="У вас установлена версия астры  "$version_astra" и она будет обновлена до 1.7.4"
            version_new="У вас установлена версия астры  "$version_astra" и установка продолжиться дальше"
                if [ $version_astra != "$version" ]; then
                    zenity --info --text="$version_old" --height=300 --width=400
                else
                    zenity --info --text="$version_new" --height=300 --width=400
                fi
            (
            #репы
            echo $passwd | sudo -S bash -c "echo -e 'deb https://dl.astralinux.ru/aldpro/stable/repository-extended/ generic main' >> /etc/apt/sources.list.d/aldpro.list"
            echo $passwd | sudo -S bash -c "echo -e 'deb https://dl.astralinux.ru/aldpro/stable/repository-main/ 2.1.0 main' >> /etc/apt/sources.list.d/aldpro.list"
            echo $passwd | sudo -S bash -c "echo -e 'deb http://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-main/ 1.7_x86-64 main contrib non-free'  > /etc/apt/sources.list"   
            echo $passwd | sudo -S bash -c "echo -e 'deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-update/ 1.7_x86-64 main contrib non-free' >> /etc/apt/sources.list"
            echo $passwd | sudo -S bash -c "echo -e 'deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free' >> /etc/apt/sources.list" 
            echo $passwd | sudo -S bash -c "echo -e 'deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free' >> /etc/apt/sources.list" 
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
#            echo $passwd | sudo -S bash -c "echo '$ipaddres $fqdn $small_fqdn' >> /etc/hosts"
            echo $passwd | sudo -S bash -c "echo '127.0.1.1 $small_fqdn' >> /etc/hosts"
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
            ) | zenity --progress --pulsate
            #меняем resolf.conf
            (
            echo $passwd | sudo -S bash -c "echo '# Generated by NetworkManager' > /etc/resolv.conf"
            echo $passwd | sudo -S bash -c "echo 'search $big_fqdn' >> /etc/resolv.conf" 
            echo $passwd | sudo -S bash -c "echo 'nameserver $dns' >> /etc/resolv.conf" 
            echo $passwd | sudo -S /opt/rbta/aldpro/client/bin/aldpro-client-installer -c "$big_fqdn" -u "$admin" -p "$pass_domain" -d "$small_fqdn" -i -f
            exit_code=$?
            # Проверка кода завершения и отображение соответствующего сообщения
                if [ $exit_code -eq 0 ]; then
                    zenity --info --title="Успех" --text="Клиент успешно подключен"
                else
                    zenity --error --title="Ошибка" --text="Ошибка при подключению к домену"
                    exit 1
                fi
            ) | zenity --progress --pulsate
            zenity --info --text="$reboot" --height=200 --width=200
        fi
else
    zenity --info --text="$internet_error" --height=300 --width=400
fi