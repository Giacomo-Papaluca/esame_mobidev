# Esperienza AR persistente

App per creare una stanza virtuale e riproporla nelle sessioni successive di ogni utente

# -branch main
Questo ramo serve per creare la stanza virtuale, caratterizzata da una serie di elementi virtuali posti dall'utente in luoghi reali del mondo mappati su coordinate dello schermo.
L'utente dovrà caricare gli elementi virtuali nella sessione e salvare la worldMap con il tasto salva (attualmente salvataggio automatico senza tasto).
Da Xcode, con il device ancora collegato e dopo aver eseguito l'app, cliccare su window -> devices and simulators e scaricare il container dell'app.
Visualizzare il contenuto del container ed estrarre il file Documents/WorldMaps/WorldMap dalla root dell'applicazione.

# -branch load
Questo ramo sarà l'applicazione finale degli utenti che vogliono accedere alla stanza virtuale.
Dopo aver estratto il file WorldMap desiderato, inserirlo tra i file della cartella del progetto Xcode di questo branch.
L'applicazione caricherà automaticamente gli elementi virtuali salvati se riconosce la stanza in cui essi sono stati inseriti
