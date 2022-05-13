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
    printf "%s;%s;%s;%s;%s\n","BSS","SSID","Frequency","Signal","Encryption"

    for (w in wifi) {
        printf "%s;%s;%s;%s;%s\n",wifi[w]["BSS"],wifi[w]["SSID"],wifi[w]["freq"],wifi[w]["sig"],wifi[w]["enc"]
    }
}