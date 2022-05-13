$1 == "BSS" {
    MAC = $2
    wifi[MAC]["BSS"] = substr($2,0,17)
    wifi[MAC]["enc"] = "Open"
}
$1 == "SSID:" {
    wifi[MAC]["SSID"] = $2
}
$1 == "freq:" {
    wifi[MAC]["freq"] = $NF
}
$1 == "signal:" {
    wifi[MAC]["sig"] = $2 " " $3
}
$3 == "suites:" {
    wifi[MAC]["enc"] = $4
}
$1 == "WEP:" {
    wifi[MAC]["enc"] = "WEP"
}
END {
    compteur = 0
    printf "%s\t\t\t%s\t%s\t\t%s\t%s\n","BSS","Frequency","Signal","Encryption","SSID"

    for (w in wifi) {
        compteur = compteur + 1
        printf "%s\t%s\t\t%s\t%s\t\t%s\n",wifi[w]["BSS"],wifi[w]["freq"],wifi[w]["sig"],wifi[w]["enc"],wifi[w]["SSID"]
    }
    printf "------------------------------\n%s Wifi discovered\n------------------------------\n", compteur
}