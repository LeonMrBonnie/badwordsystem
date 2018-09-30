//Badword System von LeonMrBonnie
//Erstellt am 30.9.2018 für das Breadfish Forum.

#define FILTERSCRIPT

//Includes
#include <a_samp>
#include <zcmd>
#include <a_mysql>

// ************  EINSTELLUNGEN:  ************** //
#define MYSQL_HOST         "127.0.0.1"   		 //IP Adresse des MySQL Servers
#define MYSQL_USER         "root"       		 //Benutzername der angemeldet wird
#define MYSQL_PASS         "root"       		 //Passwort des Benutzers
#define MYSQL_DBSE         "samp"        	     //Name der Datenbank
#define MYSQL_TABLENAME    "server_badwords"     //Tabellenname für die Badwords

#define MAX_BADWORDS     100      //Maximale Anzahl an Badwords

//Dialoge
#define DIALOG_BADWORD   	 30000
#define DIALOG_BADWORDLIST   30001
#define DIALOG_BADWORDADD    30002
#define DIALOG_BADWORDREMOVE 30003

//Farben
#define COLOR_LIGHTBLUE 0x33CCFFAA
#define HTML_WHITE     "{FFFFFF}"
#define HTML_RED       "{f44242}"

//Enum
enum BadwordEnum
{
	Badword[32],
	CreatedBy[MAX_PLAYER_NAME],
	Exists
};

//Variablen
new MySQL:badword_handle;
new BadwordInfo[MAX_BADWORDS][BadwordEnum];
new badwords;

//----------------------------------------------------------------------------------------------//
//***** Publics *****
public OnFilterScriptInit()
{
	print("\n-----------------------------------");
	print(" Badword System von LeonMrBonnie geladen");
	print("-----------------------------------\n");

	DatabaseConnect();
	return 1;
}

public OnFilterScriptExit()
{
	mysql_close(badword_handle);
	return 1;
}

public OnPlayerText(playerid, text[])
{
	if(ContainsBadword(text))
	{
		SendClientMessage(playerid, COLOR_LIGHTBLUE, "BADWORDS: Deine Nachricht hat ein Badword enthalten. Die Nachricht wurde nicht versendet.");
		return 0;
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_BADWORD:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0: //Badwords auflisten
					{
						if(badwords == 0) return SendClientMessage(playerid, COLOR_LIGHTBLUE, "BADWORDS: Es sind keine Badwords vorhanden.");
						new dialogstring[2048],string[64];
						dialogstring = "Badword\tHinzugefügt von\n";
						for(new i; i<badwords+1; i++)
						{
							if(BadwordInfo[i][Exists] == 0) continue;
							format(string,sizeof(string),"%s\t%s\n",BadwordInfo[i][Badword],BadwordInfo[i][CreatedBy]);
							strcat(dialogstring, string);
						}
						ShowPlayerDialog(playerid, DIALOG_BADWORDLIST, DIALOG_STYLE_TABLIST_HEADERS, "Badwords: "HTML_RED"Badwords auflisten", dialogstring, "Zurück", "");
					}
					case 1: //Badword hinzufügen
					{
						ShowPlayerDialog(playerid, DIALOG_BADWORDADD, DIALOG_STYLE_INPUT, "Badwords: "HTML_RED"Badword hinzufügen", ""HTML_WHITE"Gib unten das Badword ein, welches du hinzufügen möchtest:","Bestätigen","Zurück");
					}
					case 2: //Badword entfernen
					{
						ShowPlayerDialog(playerid, DIALOG_BADWORDREMOVE, DIALOG_STYLE_INPUT, "Badwords: "HTML_RED"Badword entfernen", ""HTML_WHITE"Gib unten das Badword ein, welches du entfernen möchtest:","Bestätigen","Zurück");
					}
				}
			}
		}
		case DIALOG_BADWORDLIST:
		{
			if(response)
			{
				ShowPlayerDialog(playerid, DIALOG_BADWORD, DIALOG_STYLE_LIST, "Badwords: "HTML_RED"Verwaltung", "Alle Badwords anzeigen\nBadword hinzufügen\nBadword entfernen", "Auswählen", "Schliessen");
			}
		}
		case DIALOG_BADWORDADD:
		{
			if(response)
			{
				if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BADWORDADD, DIALOG_STYLE_INPUT, "Badwords: "HTML_RED"Badword hinzufügen", ""HTML_RED"Das Eingabefeld ist leer.\n"HTML_WHITE"Gib unten das Badword ein, welches du hinzufügen möchtest:","Bestätigen","Zurück");
				if(strlen(inputtext) > 32) return ShowPlayerDialog(playerid, DIALOG_BADWORDADD, DIALOG_STYLE_INPUT, "Badwords: "HTML_RED"Badword hinzufügen", ""HTML_RED"Ein Badword darf nur 32 Zeichen lang sein.\n"HTML_WHITE"Gib unten das Badword ein, welches du hinzufügen möchtest:","Bestätigen","Zurück");
				if(BadwordExists(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BADWORDADD, DIALOG_STYLE_INPUT, "Badwords: "HTML_RED"Badword hinzufügen", ""HTML_RED"Dieses Badword gibt es bereits.\n"HTML_WHITE"Gib unten das Badword ein, welches du hinzufügen möchtest:","Bestätigen","Zurück");
				if(badwords >= MAX_BADWORDS) return ShowPlayerDialog(playerid, DIALOG_BADWORDADD, DIALOG_STYLE_INPUT, "Badwords: "HTML_RED"Badword hinzufügen", ""HTML_RED"Die maximale Anzahl an Badwords wurde bereits erreicht.\n"HTML_WHITE"Gib unten das Badword ein, welches du hinzufügen möchtest:","Bestätigen","Zurück");

				AddBadword(playerid, inputtext);
			}
			else
			{
				ShowPlayerDialog(playerid, DIALOG_BADWORD, DIALOG_STYLE_LIST, "Badwords: "HTML_RED"Verwaltung", "Alle Badwords anzeigen\nBadword hinzufügen\nBadword entfernen", "Auswählen", "Schliessen");
			}
		}
		case DIALOG_BADWORDREMOVE:
		{
			if(response)
			{
				if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BADWORDREMOVE, DIALOG_STYLE_INPUT, "Badwords: "HTML_RED"Badword entfernen", ""HTML_RED"Das Eingabefeld ist leer.\n"HTML_WHITE"Gib unten das Badword ein, welches du entfernen möchtest:","Bestätigen","Zurück");
				if(!BadwordExists(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BADWORDREMOVE, DIALOG_STYLE_INPUT, "Badwords: "HTML_RED"Badword entfernen", ""HTML_RED"Dieses Badword gibt es nicht.\n"HTML_WHITE"Gib unten das Badword ein, welches du entfernen möchtest:","Bestätigen","Zurück");

				RemoveBadword(playerid, inputtext);
			}
			else
			{
				ShowPlayerDialog(playerid, DIALOG_BADWORD, DIALOG_STYLE_LIST, "Badwords: "HTML_RED"Verwaltung", "Alle Badwords anzeigen\nBadword hinzufügen\nBadword entfernen", "Auswählen", "Schliessen");
			}
		}
	}
	return 0;
}

forward OnBadwordsLoad();
public OnBadwordsLoad() //Badwords werden aus der Datenbank geladen
{
	new rows;
	cache_get_row_count(rows);
	if(rows == 0)
	{	
		print("[BADWORDS]: Es wurden 0 Badwords aus der Datenbank geladen.");
		return 1;
	}
	else
	{
		for(new i; i<rows; i++)
		{
			cache_get_value_name(i, "Badword",BadwordInfo[i][Badword],32);
			cache_get_value_name(i, "CreatedBy",BadwordInfo[i][CreatedBy],24);
			BadwordInfo[i][Exists] = 1;
			badwords++;
		}
		printf("[BADWORDS]: Es wurden %d Badwords aus der Datenbank geladen.",rows);
	}
	return 1;
}

//----------------------------------------------------------------------------------------------//
//***** Befehle *****
CMD:badwords(playerid)
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, COLOR_LIGHTBLUE, "Du bist kein Admin.");

	ShowPlayerDialog(playerid, DIALOG_BADWORD, DIALOG_STYLE_LIST, "Badwords: "HTML_RED"Verwaltung", "Alle Badwords anzeigen\nBadword hinzufügen\nBadword entfernen", "Auswählen", "Schliessen");

	return 1;
}

CMD:addbadword(playerid,params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, COLOR_LIGHTBLUE, "Du bist kein Admin.");
	if(isnull(params)) return SendClientMessage(playerid, COLOR_LIGHTBLUE, "/addbadword [Badword]");
	if(BadwordExists(params)) return SendClientMessage(playerid, COLOR_LIGHTBLUE, "Dieses Badword existiert bereits.");
	if(badwords >= MAX_BADWORDS) return SendClientMessage(playerid, COLOR_LIGHTBLUE, "Die maximale Anzahl an Badwords wurde bereits erreicht.");

	AddBadword(playerid, params);

	return 1;
}

CMD:removebadword(playerid,params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, COLOR_LIGHTBLUE, "Du bist kein Admin.");
	if(isnull(params)) return SendClientMessage(playerid, COLOR_LIGHTBLUE, "/removebadword [Badword]");
	if(!BadwordExists(params)) return SendClientMessage(playerid, COLOR_LIGHTBLUE, "Dieses Badword existiert nicht.");

	RemoveBadword(playerid, params);

	return 1;
}

CMD:listbadwords(playerid)
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, COLOR_LIGHTBLUE, "Du bist kein Admin.");
	if(badwords == 0) return SendClientMessage(playerid, COLOR_LIGHTBLUE, "BADWORDS: Es sind keine Badwords vorhanden.");

	new dialogstring[2048],string[64];
	dialogstring = "Badword\tHinzugefügt von\n";

	for(new i; i<badwords+1; i++)
	{
		if(BadwordInfo[i][Exists] == 0) continue;
		format(string,sizeof(string),"%s\t%s\n",BadwordInfo[i][Badword],BadwordInfo[i][CreatedBy]);
		strcat(dialogstring, string);
	}

	ShowPlayerDialog(playerid, DIALOG_BADWORDLIST, DIALOG_STYLE_TABLIST_HEADERS, "Badwords: "HTML_RED"Badwords auflisten", dialogstring, "Zurück", "");

	return 1;
}

//----------------------------------------------------------------------------------------------//
//***** Funktionen/Stocks *****
stock DatabaseConnect(versuch = 3) //Verbindung zur Datenbank herstellen
{
	mysql_log();
	badword_handle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DBSE);
	
	if(mysql_errno(badword_handle) != 0)
	{
		if(versuch > 1)
		{
			print("[BADWORDS]: Es konnte keine Verbindung zur Datenbank hergestellt werden.");
			printf("[BADWORDS]: Starte neuen Verbindungsversuch (Versuch: %d).", versuch-1);
			return DatabaseConnect(versuch-1);
		}
		else
		{
			print("[BADWORDS]: Es konnte keine Verbindung zur Datenbank hergestellt werden.");
			print("[BADWORDS]: Bitte prüfen Sie die Verbindungsdaten.");
			print("[BADWORDS]: Der Server wird heruntergefahren.");
			return SendRconCommand("exit");
		}
	}
	printf("[BADWORDS]: Die Verbindung zur Datenbank wurde erfolgreich hergestellt! Handle: %d", _:badword_handle);
	mysql_query(badword_handle,"CREATE TABLE IF NOT EXISTS `"MYSQL_TABLENAME"` (`ID` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,`Badword` varchar(32) NOT NULL,`CreatedBy` varchar(24) NOT NULL DEFAULT 'System')");
	mysql_tquery(badword_handle, "SELECT * FROM `"MYSQL_TABLENAME"`","OnBadwordsLoad");
	return 1;
}

AddBadword(playerid, badword[])
{
	new Query[96],message[96];
	mysql_format(badword_handle,Query,sizeof(Query),"INSERT INTO `"MYSQL_TABLENAME"` (Badword, CreatedBy) VALUES ('%e', '%e')",badword,GetName(playerid));
	mysql_tquery(badword_handle,Query);

	badwords++;
	format(BadwordInfo[badwords][Badword],32,"%s",badword);
	format(BadwordInfo[badwords][CreatedBy],24,"%s",GetName(playerid));
	BadwordInfo[badwords][Exists] = 1;

	format(message,sizeof(message),"BADWORDS: %s hat das Badword '%s' hinzugefügt.",GetName(playerid),badword);
	SendClientMessageToAll(COLOR_LIGHTBLUE, message);

	printf("[BADWORDS]: Badword '%s' von %s hinzugefügt",badword,GetName(playerid));

	return 1;
}

RemoveBadword(playerid, badword[])
{
	new Query[96],message[96],enumid;
	mysql_format(badword_handle,Query,sizeof(Query),"DELETE FROM `"MYSQL_TABLENAME"` WHERE `Badword`='%e'",badword);
	mysql_tquery(badword_handle,Query);

	for(new i; i<badwords+1; i++)
	{
		if(!strcmp(BadwordInfo[i][Badword], badword)) enumid = i;
	}
	badwords--;
	format(BadwordInfo[enumid][Badword],32,"");
	format(BadwordInfo[enumid][CreatedBy],24,"");
	BadwordInfo[enumid][Exists] = 0;

	format(message,sizeof(message),"BADWORDS: %s hat das Badword '%s' entfernt.",GetName(playerid),badword);
	SendClientMessageToAll(COLOR_LIGHTBLUE, message);

	printf("[BADWORDS]: Badword '%s' von %s entfernt",badword,GetName(playerid));

	return 1;
}

BadwordExists(badword[])
{
	for(new i; i<badwords+1; i++)
	{
		if(BadwordInfo[i][Exists] == 0) continue;
		if(!strcmp(badword, BadwordInfo[i][Badword], true)) return true;
	}
	return false;
}

ContainsBadword(text[])
{
	for(new i; i<badwords+1; i++)
	{
		if(BadwordInfo[i][Exists] == 0) continue;
		if(strfind(text, BadwordInfo[i][Badword], true) != -1) return true;
	}
	return false;
}

GetName(playerid)
{
	new PlayerName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, PlayerName, MAX_PLAYER_NAME);
	return PlayerName;
}