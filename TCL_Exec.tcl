##########################################################################
#
# Script Name: TCL_Exec.tcl
#
# Information:
#	TCL_Exec permet d'executer des commandes TCL via IRC a votre robot.
#
# Copyright 2008-2022 by ZarTek-Creole
#
# Create by ZarTek @ https://github.com/ZarTek-Creole
#
# Changelog V1.0.20150219 by ZarTek 19.02.2015
#	- Creation d'un namespace pour eviter tout conflit avec d'autres scripts
#	- Mise en package TCLExec pour pouvoir verifier sa presence "package require TCLExec"
#	- Dechargement propre au rehash et au restart
#	- Multi commandes, !tcl ou !nicktcl
#	- Autoriser tout les salons ou que certains
#	- Autoriser tout les nick ou que certains
#	- Creation d'un flag +E qui bypass la verification nick/salon : .chattr nick +E
##########################################################################
if { [info commands ::TCLExec::uninstall] eq "::TCLExec::uninstall" } { ::TCLExec::uninstall }
package require Tcl 8.5
namespace eval ::TCLExec {
#############################################################################
### Initialisation
#############################################################################
	array set SCRIPT {
		"name"				"TCL Exec"
		"version"			"1.0.4"
		"auteur"			"ZarTek"
	}
	set PATH_SCRIPT "[file dirname [file normalize [info script]]]/TCL_Exec.conf"
    if { [ catch {
        source ${PATH_SCRIPT}
    } err ] } {
        putlog "[namespace current] > Error: Chargement du fichier '${PATH_SCRIPT}' > $err"
        return -code error $err
    }
    set List_Var_Conf		 [list  \
				"Prefix_CMD"        \
				"Multi_CMD"         \
				"List_Users"        \
				"List_Salons" 		\
    ];
    foreach varName [split ${List_Var_Conf}] {
        if { ![info exists [namespace current]::${varName}] } {
            putlog "[namespace current] > Error: La configuration ${varName} est manquante dans ${PATH_SCRIPT}"
            exit
        }
    }
}

# Procédure de désinstallation
# (le script se désinstalle totalement avant chaque rehash ou é chaque relecture au moyen de la commande "source" ou autre)
proc ::TCLExec::uninstall {args} {
	putlog "Désallocation des ressources de \002${::TCLExec::SCRIPT(name)}\002...";
	foreach binding [lsearch -inline -all -regexp [binds *[set ns [string range [namespace current] 2 end]]*] " \{?(::)?${ns}"] {
		unbind [lindex ${binding} 0] [lindex ${binding} 1] [lindex ${binding} 2] [lindex ${binding} 4];
	}
	namespace delete ::TCLExec
}

if { ${::TCLExec::Multi_CMD} == 1 } {
	bind pub - "${::TCLExec::Prefix_CMD}" ::TCLExec::Command
} elseif { ${::TCLExec::Multi_CMD} == 2} {
	bind pub - "${::TCLExec::Prefix_CMD}" ::TCLExec::Command
	bind pub - "${::botnet-nick}tcl" ::TCLExec::Command
	bind pub - "${::botnet-nick}${::TCLExec::Prefix_CMD}" ::TCLExec::Command
	bind pub - "[string tolower ${::botnet-nick}]${::TCLExec::Prefix_CMD}" ::TCLExec::Command
	bind pub - "[string toupper ${::botnet-nick}]${::TCLExec::Prefix_CMD}" ::TCLExec::Command
	bind pub - "[string tolower ${::botnet-nick}]tcl" ::TCLExec::Command
	bind pub - "[string toupper ${::botnet-nick}]tcl" ::TCLExec::Command
} elseif {$::TCLExec::Multi_CMD == 3} {
	bind pub - "${::botnet-nick}tcl" ::TCLExec::Command
	bind pub - "${::botnet-nick}tcl" ::TCLExec::Command
	bind pub - "${::botnet-nick}${::TCLExec::Prefix_CMD}" ::TCLExec::Command
	bind pub - "[string tolower ${::botnet-nick}]${::TCLExec::Prefix_CMD}" ::TCLExec::Command
	bind pub - "[string toupper ${::botnet-nick}]${::TCLExec::Prefix_CMD}" ::TCLExec::Command
	bind pub - "[string tolower ${::botnet-nick}]tcl" ::TCLExec::Command
	bind pub - "[string toupper ${::botnet-nick}]tcl" ::TCLExec::Command

}

proc ::TCLExec::Command { nick host hand chan args } {
	putlog "----------------------------->>>>>>>>>>>>> $args"
	variable List_Users		${::TCLExec::List_Users}
	variable List_Salons	${::TCLExec::List_Salons}
	if {![matchattr ${nick} E]} {
		if {
			${List_Users} != "" 								&& \
			[lsearch -glob ${List_Users} ${nick}] == -1
		} {
			putserv "privmsg ${chan} :Nickname '${nick}' have access denied.";
			return 0;
		}
		if {
			${List_Salons} != "" 							&& \
			[lsearch -glob ${List_Salons} ${chan}] == -1
		} {
			putserv "privmsg ${chan} :Channel '${chan}' have access denied.";
			return 0;
		}
	}
	set args 	[lindex ${args} 0];
	set start 	[clock clicks];
	set errnum 	[catch {eval ${args}} error];
	set end 	[clock clicks];
	if { ${error} == "" } {
		set error "<empty string>";
	}
	switch -- ${errnum} {
		0 {
			if { ${error} == "<empty string>" } { set error "OK"; } { set error "OK: ${error}"; }
		}
		2 {
			set error "Return: ${error}";
		}
		1 {
			set error "Error: ${error}";
		}
		default {set error "${errnum}: ${error}"}
	}
	set error "${error} - [expr (${end}-${start})/1000.0] ms";
	set error [split ${error} "\n"];
	foreach line ${error} { putserv "PRIVMSG ${chan} :${line}"; }
}

package		provide TCLExec ${::TCLExec::SCRIPT(version)};
putlog "${::TCLExec::SCRIPT(name)} v${::TCLExec::SCRIPT(version)} by ${::TCLExec::SCRIPT(auteur)}.";
