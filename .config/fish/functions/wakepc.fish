function wakepc --description "Wake home PC via Pi"
    ssh junji@junji-pi "wakeonlan b4:2e:99:3c:df:ad"
end
