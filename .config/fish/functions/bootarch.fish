function bootarch --description "Wake home PC from Windows sleep and reboot into Arch"
    echo "Sending WoL packet..."
    ssh junji@junji-pi "wakeonlan b4:2e:99:3c:df:ad"

    echo "Waiting for Windows to come online..."
    for i in (seq 1 30)
        ping -c 1 -W 2 junji-pc-win &>/dev/null
        if ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no juliu@junji-pc-win "echo ok" &>/dev/null
            echo "Online. Rebooting into Arch..."
            ssh juliu@junji-pc-win "reboot"
            return
        end
        sleep 5
    end

    echo "Timed out waiting for junji-pc-win"
    return 1
end
