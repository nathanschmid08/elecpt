#!/usr/bin/perl
use strict;
use warnings;
use File::Path qw(make_path);
use Cwd;
use Term::ANSIColor qw(colored);

# Terminal colors and formatting
sub print_header {
    my $text = shift;
    print colored("=" x 60, 'cyan') . "\n";
    print colored(" " x ((60 - length($text)) / 2) . $text, 'bold cyan') . "\n";
    print colored("=" x 60, 'cyan') . "\n\n";
}

sub print_step {
    my ($step, $description) = @_;
    print colored("[$step]", 'bold green') . " " . colored($description, 'white') . "\n";
}

sub print_success {
    my $text = shift;
    print colored("OK ", 'bold green') . colored($text, 'green') . "\n";
}

sub print_error {
    my $text = shift;
    print colored("ERROR ", 'bold red') . colored($text, 'red') . "\n";
}

sub print_info {
    my $text = shift;
    print colored("INFO ", 'bold blue') . colored($text, 'blue') . "\n";
}

sub print_progress {
    my $text = shift;
    print colored("PROGRESS ", 'bold yellow') . colored($text, 'yellow') . "\n";
}

# Configuration
my $project_name = "meine-electron-app";
my $desktop_path = "$ENV{HOME}/Schreibtisch/$project_name";

print_header("ELECTRON APP GENERATOR");
print_info("Erstelle neue Electron-App");
print "\n";

# 1. Verzeichnis erstellen
print_step("1/7", "Erstelle Projektverzeichnis...");
if (make_path($desktop_path)) {
    print_success("Verzeichnis erstellt: $desktop_path");
} else {
    print_error("Konnte Verzeichnis nicht erstellen: $!");
    die;
}

# 2. Ins Verzeichnis wechseln
print_step("2/7", "Wechsle ins Projektverzeichnis...");
if (chdir $desktop_path) {
    print_success("Verzeichnis gewechselt");
} else {
    print_error("Konnte nicht ins Verzeichnis wechseln: $!");
    die;
}

# 3. Node-Projekt initialisieren
print_step("3/7", "Initialisiere Node.js Projekt...");
if (system("npm init -y > /dev/null 2>&1") == 0) {
    print_success("package.json erstellt");
} else {
    print_error("npm init fehlgeschlagen");
    die;
}

# 4. Electron installieren
print_step("4/7", "Installiere Electron...");
print_progress("Das kann einen Moment dauern...");
if (system("npm install electron --save-dev > /dev/null 2>&1") == 0) {
    print_success("Electron erfolgreich installiert");
} else {
    print_error("Electron Installation fehlgeschlagen");
    die;
}

# 5. package.json anpassen
print_step("5/7", "Konfiguriere package.json...");
open(my $pkg, "+<", "package.json") or die "Kann package.json nicht öffnen: $!";
my $json = do { local $/; <$pkg> };

# main auf main.js setzen
$json =~ s/"main":\s*".*?"/"main": "main.js"/;

# scripts komplett auf "start": "electron ." setzen
if ($json =~ /"scripts":\s*{.*?}/s) {
    $json =~ s/"scripts":\s*{.*?}/"scripts": {\n    "start": "electron ."\n  }/s;
} else {
    $json =~ s/({)/$1\n  "scripts": {\n    "start": "electron ."\n  },/;
}

seek($pkg, 0, 0);
print $pkg $json;
truncate($pkg, tell($pkg));
close($pkg);
print_success("package.json konfiguriert");

# 6. Dateien erstellen
print_step("6/7", "Erstelle Anwendungsdateien...");

# main.js
open(my $main_fh, ">", "main.js") or die "Kann main.js nicht erstellen: $!";
print $main_fh <<'MAIN';
const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    },
    icon: path.join(__dirname, 'assets/icon.png'),
    titleBarStyle: 'default',
    show: false
  });

  win.loadFile('index.html');
  
  // Zeige Fenster wenn bereit
  win.once('ready-to-show', () => {
    win.show();
  });

  // Entwickler-Tools in Development
  if (process.env.NODE_ENV === 'development') {
    win.webContents.openDevTools();
  }
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
MAIN
close($main_fh);
print_success("main.js erstellt");

# index.html - Korrigierte Version
open(my $html_fh, ">", "index.html") or die "Kann index.html nicht erstellen: $!";
print $html_fh <<'HTML';
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Vanilla App</title>
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&display=swap" rel="stylesheet" />
<style>
:root {
--background-color: #ffffff;
--text-color: #111111;
--text-secondary: #666666;
--accent-color: #007aff;
 }
* {
margin: 0;
padding: 0;
box-sizing: border-box;
 }
body {
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
background-color: var(--background-color);
color: var(--text-color);
line-height: 1.6;
 }
#root {
min-height: 100vh;
display: flex;
align-items: center;
justify-content: center;
padding: 2rem;
 }
.app {
text-align: center;
max-width: 600px;
width: 100%;
 }
.image-wrapper {
width: 150px;
height: 150px;
margin: 0 auto 2rem;
background-color: #f0f0f0;
border-radius: 50%;
display: flex;
align-items: center;
justify-content: center;
box-shadow: 0 6px 16px rgba(0, 0, 0, 0.05);
 }
.image-wrapper img {
width: 80px;
height: 80px;
object-fit: contain;
 }
.app-title {
font-size: 2.2rem;
font-weight: 600;
margin-bottom: 1rem;
 }
.app-description {
font-size: 1.1rem;
color: var(--text-secondary);
max-width: 500px;
margin: 0 auto;
 }
@media (max-width: 600px) {
.app-title {
font-size: 1.8rem;
 }
.app-description {
font-size: 1rem;
 }
.image-wrapper {
width: 120px;
height: 120px;
 }
.image-wrapper img {
width: 60px;
height: 60px;
 }
 }
</style>
</head>
<body>
<div id="root">
<div class="app">
<div class="image-wrapper">
<img src="https://raw.githubusercontent.com/nathanschmid08/elecpt/main/vanilla.png" alt="Vanilla Icon" />
</div>
<h1 class="app-title">Vanilla App</h1>
<p class="app-description">Generated by elecpt</p>
</div>
</div>
<script>
document.addEventListener('DOMContentLoaded', function () {
console.log('Electron App gestartet!');
 });
</script>
</body>
</html>
HTML
close($html_fh);
print_success("index.html erstellt");

# styles.css wird nicht mehr erstellt, da CSS inline im HTML ist

print_step("7/8", "Finalisiere Setup...");
print_success("Alle Dateien erfolgreich erstellt");

print "\n";
print_header("SETUP ABGESCHLOSSEN");
print_success("Electron-App '$project_name' wurde erfolgreich erstellt!");
print_info("Projektverzeichnis: $desktop_path");
print "\n";

# 7. VS Code öffnen
print_progress("Öffne Projekt in VS Code...");
if (system("code . > /dev/null 2>&1") == 0) {
    print_success("VS Code erfolgreich geöffnet");
} else {
    print_error("VS Code konnte nicht geöffnet werden");
    print_info("Versuche manuell: cd '$desktop_path' && code .");
}

# 8. npm start automatisch ausführen
print_progress("Starte die Electron-App...");
print colored("LOADING ", 'yellow') . colored("App wird gestartet, bitte warten...", 'yellow') . "\n\n";

if (system("npm start") == 0) {
    print_success("App erfolgreich gestartet!");
} else {
    print_error("Fehler beim Starten der App");
    print_info("Versuche manuell: cd '$desktop_path' && npm start");
}

print "\n";
print colored("SUCCESS ", 'bold green') . colored("Viel Spass mit deiner neuen Electron-App!", 'bold green') . "\n";
print colored("TIPP ", 'blue') . colored("Bearbeite die Dateien in VS Code und starte neu mit 'npm start'", 'blue') . "\n";