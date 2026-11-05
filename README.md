# Container Security Laboratory — Docker Socket Exposure & Container Escape

Laboratorio riproducibile che dimostra un **container escape** basato sull'esposizione
del socket del daemon Docker (`/var/run/docker.sock`) all'interno di un container
applicativo. Il laboratorio include anche la **catena d'attacco completa** (bonus):
un'applicazione web vulnerabile a *command injection* viene usata come punto d'ingresso
iniziale, e da lì si abusa del socket montato per ottenere privilegi di root sull'host.

> ⚠️ **Avvertenza.** Questo materiale è esclusivamente didattico e va eseguito **solo**
> in un ambiente isolato e monouso (una macchina virtuale di laboratorio dedicata).
> La dimostrazione scrive un file di prova e legge un file sensibile sul filesystem
> dell'host *del laboratorio*. Non eseguire su sistemi di produzione o su macchine
> condivise.

---

## 1. Scenario

Lo scenario modella un errore di configurazione frequente nel mondo reale. Molti
strumenti operativi (dashboard di gestione container, agenti di monitoraggio, runner
di CI/CD) hanno bisogno di parlare con il daemon Docker e, per comodità, vengono
avviati con il socket del daemon montato al loro interno:

```
-v /var/run/docker.sock:/var/run/docker.sock
```

Il socket è il punto d'ingresso dell'API del daemon, che gira come **root sull'host**.
Chiunque possa scrivere sul socket può chiedere al daemon di avviare un nuovo container
con il filesystem dell'host montato, ottenendo di fatto accesso root all'host. Non si
tratta di una vulnerabilità di Docker, ma di una configurazione che annulla il confine
di isolamento previsto.

In questo laboratorio il container esposto è una finta *Container Operations Dashboard*:
un'app web con una funzione di diagnostica (`ping`) affetta da command injection. Questo
rende la catena coerente e realistica: è proprio il tipo di applicazione che, a torto,
monta il socket.

## 2. Architettura del laboratorio

```
            HTTP :8080                 bind mount
Attaccante ───────────▶  ops-dashboard  ──────────▶  /var/run/docker.sock
                         (container)                        │
                         app Flask + docker CLI             ▼
                                                     dockerd (root)  ── HOST
                                                            │
                                                            ▼
                                                container figlio "privilegiato"
                                                   -v /:/host  ──▶  filesystem host
```

Un unico servizio (`dashboard`) viene definito in `environment/docker-compose.yml`.
La sua immagine è costruita da `application/`. Il bind mount del socket è l'unica
configurazione "pericolosa" introdotta deliberatamente.

## 3. Struttura del repository

```
assignment/
├── README.md                     questo file
├── references.md                 fonti e CVE citate
├── report/
│   └── report.pdf                relazione tecnica (PDF finale)
├── environment/
│   └── docker-compose.yml        orchestrazione + misconfigurazione (socket)
├── application/                  componente bonus: app vulnerabile
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
└── scripts/
    ├── setup.sh                  costruisce e avvia l'ambiente
    ├── demo.sh                   esegue la catena d'attacco e verifica il risultato
    └── cleanup.sh                arresta e rimuove tutto
```

## 4. Prerequisiti

- Linux con **Docker Engine** e **Docker Compose v2** (`docker compose`).
- `curl` sull'host (per lo script di dimostrazione).
- Connettività di rete al primo avvio (per scaricare le immagini di base e `alpine`).
- L'utente che esegue i comandi deve poter usare Docker (gruppo `docker` o `sudo`).

## 5. Assunzioni di sicurezza

- Il socket Docker è montato in lettura/scrittura nel container applicativo.
- L'applicazione espone una vulnerabilità di command injection raggiungibile via rete.
- Il daemon Docker gira come root (configurazione predefinita, non *rootless*).
- Non sono attivi profili di hardening aggiuntivi (nessun socket proxy, nessun
  user namespace remapping, profili seccomp/AppArmor di default).

Queste assunzioni sono realistiche e rappresentano la condizione tipica in cui la
misconfigurazione produce impatto massimo.

## 6. Build e avvio

```bash
bash scripts/setup.sh
```

Al termine la dashboard è raggiungibile su `http://localhost:8080`.
In alternativa, manualmente:

```bash
docker compose -f environment/docker-compose.yml up -d --build
```

## 7. Dimostrazione dell'exploit

```bash
bash scripts/demo.sh
```

Lo script invia all'applicazione un payload che sfrutta la command injection per
eseguire, tramite il socket montato, un nuovo container con il filesystem dell'host
montato in `/host`. Il container figlio scrive una prova in `/tmp/ESCAPE_PROOF.txt`
sull'host e vi aggiunge la prima riga di `/etc/shadow` dell'host, dimostrando lettura
di dati sensibili con privilegi di root.

Payload (concettualmente):

```
127.0.0.1; docker run --rm -v /:/host alpine sh -c '<comandi sull'host>'
```

## 8. Verifica del risultato

Lo script `demo.sh` stampa automaticamente il contenuto della prova. Per verificare
manualmente, sull'**host**:

```bash
cat /tmp/ESCAPE_PROOF.txt
```

Poiché `demo.sh` viene eseguito sull'host e il file è stato creato da un container,
la sua presenza con quel contenuto dimostra che il confine container→host è stato
superato. La riga proveniente da `/etc/shadow` conferma l'accesso in lettura a file
di sistema riservati dell'host.

## 9. Arresto e rimozione

```bash
bash scripts/cleanup.sh
```

Rimuove i container, l'immagine `ops-dashboard:lab`, i volumi e il file di prova
`/tmp/ESCAPE_PROOF.txt`.

## 10. Note sulla riproducibilità

L'intero ambiente è ricostruibile dai file del repository, senza passaggi manuali
non documentati. La relazione in `report/report.pdf` spiega il meccanismo di
isolamento, perché la configurazione lo indebolisce, l'intera sequenza di
sfruttamento e le contromisure.
