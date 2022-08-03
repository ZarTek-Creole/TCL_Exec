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
if {[info commands ::TCLExec::uninstall] eq "::TCLExec::uninstall"} { ::TCLExec::uninstall }
package require Tcl 8.5
namespace eval TCLExec {
	variable Prefix_CMD		"tcl";			# Commande qui permet d'execut� du code TCL.
	variable Multi_CMD		"2";			# Multi Commandes: 
											# 1-> !<prefix>
											# 2-> !bot<prefix> et !<prefix>
											# 3-> !bot<prefix>
	variable List_Users		"ZarTek will2 gtturboulette";	# Liste des utilisateurs autoriser. Laisser vide pour tout le monde
	variable List_Salons	"";				# Liste des salons autoriser. Laisser vide pour autoriser tout les salons
	
###########################
# Fin de la Configuration #
###########################

#############################################################################
### Initialisation
#############################################################################

	variable	version		"1.0.20150219";
	variable	ScriptName	"TCL Exec V$version";
	package		provide TCLExec $version;

	# Proc�dure de d�sinstallation
	# (le script se d�sinstalle totalement avant chaque rehash ou � chaque relecture au moyen de la commande "source" ou autre)
	proc uninstall {args} {
		putlog "D�sallocation des ressources de \002$::TCLExec::ScriptName\002...";
		foreach binding [lsearch -inline -all -regexp [binds *[set ns [string range [namespace current] 2 end]]*] " \{?(::)?$ns"] {
			unbind [lindex $binding 0] [lindex $binding 1] [lindex $binding 2] [lindex $binding 4];
		}
		foreach running_timer [timers] {
			if { [::tcl::string::match "*[namespace current]::*" [lindex $running_timer 1]] } { killtimer [lindex $running_timer 2] }
		}
		foreach running_utimer [utimers] {
			if { [::tcl::string::match "*[namespace current]::*" [lindex $running_utimer 1]] } { killutimer [lindex $running_utimer 2] }
		}
		namespace delete ::TCLExec
	}

	
	if {$::TCLExec::Multi_CMD == 1} {
		bind pub - "$::TCLExec::Prefix_CMD" ::TCLExec::Command
	} elseif {$::TCLExec::Multi_CMD == 2} {
		bind pub - "$::TCLExec::Prefix_CMD" ::TCLExec::Command
		bind pub - "${::botnet-nick}tcl" ::TCLExec::Command
		bind pub - "${::botnet-nick}$::TCLExec::Prefix_CMD" ::TCLExec::Command
		bind pub - "[string tolower ${::botnet-nick}]$::TCLExec::Prefix_CMD" ::TCLExec::Command
		bind pub - "[string toupper ${::botnet-nick}]$::TCLExec::Prefix_CMD" ::TCLExec::Command
		bind pub - "[string tolower ${::botnet-nick}]tcl" ::TCLExec::Command
		bind pub - "[string toupper ${::botnet-nick}]tcl" ::TCLExec::Command
	} elseif {$::TCLExec::Multi_CMD == 3} {
		bind pub - "${::botnet-nick}tcl" ::TCLExec::Command
		bind pub - "${::botnet-nick}tcl" ::TCLExec::Command
		bind pub - "${::botnet-nick}$::TCLExec::Prefix_CMD" ::TCLExec::Command
		bind pub - "[string tolower ${::botnet-nick}]$::TCLExec::Prefix_CMD" ::TCLExec::Command
		bind pub - "[string toupper ${::botnet-nick}]$::TCLExec::Prefix_CMD" ::TCLExec::Command
		bind pub - "[string tolower ${::botnet-nick}]tcl" ::TCLExec::Command
		bind pub - "[string toupper ${::botnet-nick}]tcl" ::TCLExec::Command

	}
	proc Command { nick host hand chan args } {
		if {![matchattr $nick E]} {
			if {$::TCLExec::List_Users != "" && [lsearch -glob $::TCLExec::List_Users $nick] == -1} { putserv "privmsg $chan :Nickname '$nick' have access denied."; return 0; }
			if {$::TCLExec::List_Salons != "" && [lsearch -glob $::TCLExec::List_Salons $chan] == -1} { putserv "privmsg $chan :Channel '$chan' have access denied."; return 0; }
		}
		set args [lindex $args 0];
		putcmdlog "$::TCLExec::Prefix_CMD: $nick $host $hand $chan $args";
		set start [clock clicks];
		set errnum [catch {eval $args} error];
		set end [clock clicks];
		if { $error == "" } { set error "<empty string>"; }
		switch -- $errnum {
			0 {
				if { $error == "<empty string>" } { set error "OK"; } { set error "OK: $error"; }
			}
			2 {
				set error "Return: $error";
			}
			1 {
				set error "Error: $error";
			}
			default {set error "$errnum: $error"}
		}
		set error "$error - [expr ($end-$start)/1000.0] ms";
		set error [split $error "\n"];
		foreach line $error { putserv "PRIVMSG $chan :$line"; }
	}
}
putlog "$::TCLExec::ScriptName Creole (Creole@GMail.Com) by ZarTek.";
