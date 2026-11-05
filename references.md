# Riferimenti

## Fonti primarie e autorevoli

1. **OWASP — Docker Security Cheat Sheet.**
   OWASP Cheat Sheet Series.
   <https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html>
   Afferma esplicitamente che concedere accesso a `/var/run/docker.sock` equivale a
   concedere accesso root illimitato all'host e che montare il socket in sola lettura
   non è una soluzione, ma rende solo più difficile lo sfruttamento.

2. **Docker — Docker daemon attack surface / Daemon socket.**
   Documentazione ufficiale Docker.
   <https://docs.docker.com/engine/security/>
   Descrive l'architettura client/daemon, il daemon che gira come root e la superficie
   d'attacco esposta dal socket/API.

3. **Docker — Protect the Docker daemon socket (remote access).**
   <https://docs.docker.com/engine/security/protect-access/>
   Linee guida ufficiali su come (non) esporre il socket e sull'uso di TLS reciproco.

4. **NIST SP 800-190 — Application Container Security Guide.**
   National Institute of Standards and Technology, 2017.
   <https://doi.org/10.6028/NIST.SP.800-190>
   Riferimento sui rischi di isolamento, privilegi e configurazione nei container.

5. **MITRE ATT&CK — Containers Matrix (Escape to Host, T1611).**
   <https://attack.mitre.org/techniques/T1611/>
   Classifica la tecnica "Escape to Host", di cui l'abuso del socket è un'istanza.

6. **CIS Docker Benchmark.**
   Center for Internet Security.
   <https://www.cisecurity.org/benchmark/docker>
   Controlli di hardening, incluso il divieto di montare il socket nei container.

## CVE correlate (vettori di escape alternativi)

7. **CVE-2024-21626 — "Leaky Vessels" (runc).**
   CWE-403 (File Descriptor Leak), CVSS v3.1 8.6 (HIGH). Interessa runc
   `>= v1.0.0-rc93, < 1.1.12`; corretta in runc 1.1.12.
   Advisory: GHSA-xr7r-f8xq-vfvv.
   <https://github.com/opencontainers/runc/security/advisories/GHSA-xr7r-f8xq-vfvv>
   Un file descriptor interno che riferisce la working directory dell'host viene
   lasciato trapelare, consentendo a un processo del container di ottenere accesso al
   filesystem dell'host. Rilevante come esempio di escape dovuto a una vulnerabilità del
   runtime, in contrapposizione all'escape da misconfigurazione dimostrato in questo
   laboratorio.

8. **CVE-2019-5736 — runc `/proc/self/exe` overwrite.**
   <https://nvd.nist.gov/vuln/detail/CVE-2019-5736>
   Consente a un container malevolo di sovrascrivere il binario `runc` sull'host e
   ottenere esecuzione di codice come root. Altro esempio di escape via vulnerabilità del
   runtime.

## Strumenti di mitigazione citati nella relazione

9. **Tecnativa — docker-socket-proxy.**
   <https://github.com/Tecnativa/docker-socket-proxy>
   Proxy che filtra le chiamate all'API Docker esponendo solo gli endpoint necessari,
   usato come contromisura quando un servizio ha davvero bisogno dell'API.

10. **Docker — Rootless mode.**
    <https://docs.docker.com/engine/security/rootless/>
    Esecuzione del daemon senza privilegi di root, che riduce l'impatto dell'abuso del
    socket.
