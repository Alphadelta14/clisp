# Liste aller Pseudofunktionen
# Bruno Haible 30.4.1995

# Der Macro PSEUDOFUN deklariert eine Pseudofunktion.
# PSEUDOFUN(fun)
# > fun: C-Funktion

# Expander f�r die Deklaration der Tabelle:
  #define PSEUDOFUN_A(fun)  Pseudofun pseudo_##fun;

# Expander f�r die Initialisierung der Tabelle:
  #define PSEUDOFUN_B(fun)  (Pseudofun)(&fun),

# Welcher Expander benutzt wird, mu� vom Hauptfile aus eingestellt werden.

PSEUDOFUN(rd_by_dummy) PSEUDOFUN(wr_by_dummy) PSEUDOFUN(rd_ch_dummy) PSEUDOFUN(wr_ch_dummy)
PSEUDOFUNSS(wr_ss_dummy) PSEUDOFUNSS(wr_ss_dummy_nogc)
#ifdef HANDLES
PSEUDOFUN(rd_ch_handle) PSEUDOFUN(wr_ch_handle_x) PSEUDOFUNSS(wr_ss_handle_x) PSEUDOFUN(rd_by_handle) PSEUDOFUN(wr_by_handle)
#endif
#if defined(KEYBOARD) || defined(MAYBE_NEXTAPP)
PSEUDOFUN(rd_ch_keyboard)
#endif
#if defined(MAYBE_NEXTAPP)
PSEUDOFUN(wr_ch_terminal) PSEUDOFUN(rd_ch_terminal)
#endif
#if defined(UNIX) || defined(MSDOS) || defined(AMIGAOS) || defined(RISCOS)
PSEUDOFUN(wr_ch_terminal1) PSEUDOFUN(rd_ch_terminal1) PSEUDOFUNSS(wr_ss_terminal1)
#ifdef MSDOS
PSEUDOFUN(wr_ch_terminal2) PSEUDOFUN(rd_ch_terminal2) PSEUDOFUNSS(wr_ss_terminal2)
#endif
#if defined(GNU_READLINE) || defined(MAYBE_NEXTAPP)
PSEUDOFUN(wr_ch_terminal3) PSEUDOFUN(rd_ch_terminal3) PSEUDOFUNSS(wr_ss_terminal3)
#endif
#endif
#ifdef SCREEN
PSEUDOFUN(wr_ch_window)
#endif
PSEUDOFUN(rd_ch_sch_file) PSEUDOFUN(wr_ch_sch_file) PSEUDOFUNSS(wr_ss_sch_file)
PSEUDOFUN(rd_ch_ch_file) PSEUDOFUN(wr_ch_ch_file)
PSEUDOFUN(rd_by_iau_file) PSEUDOFUN(wr_by_iau_file)
PSEUDOFUN(rd_by_ias_file) PSEUDOFUN(wr_by_ias_file)
PSEUDOFUN(rd_by_ibu_file) PSEUDOFUN(wr_by_ibu_file)
PSEUDOFUN(rd_by_ibs_file) PSEUDOFUN(wr_by_ibs_file)
PSEUDOFUN(rd_by_icu_file) PSEUDOFUN(wr_by_icu_file)
PSEUDOFUN(rd_by_ics_file) PSEUDOFUN(wr_by_ics_file)
PSEUDOFUN(rd_by_synonym) PSEUDOFUN(wr_by_synonym) PSEUDOFUN(rd_ch_synonym) PSEUDOFUN(wr_ch_synonym) PSEUDOFUNSS(wr_ss_synonym)
PSEUDOFUN(wr_by_broad) PSEUDOFUN(wr_ch_broad) PSEUDOFUNSS(wr_ss_broad)
PSEUDOFUN(rd_by_concat) PSEUDOFUN(rd_ch_concat)
PSEUDOFUN(rd_by_twoway) PSEUDOFUN(wr_by_twoway) PSEUDOFUN(rd_ch_twoway) PSEUDOFUN(wr_ch_twoway) PSEUDOFUNSS(wr_ss_twoway)
PSEUDOFUN(rd_by_echo) PSEUDOFUN(rd_ch_echo)
PSEUDOFUN(rd_ch_str_in)
PSEUDOFUN(wr_ch_str_out) PSEUDOFUNSS(wr_ss_str_out)
PSEUDOFUN(wr_ch_str_push)
PSEUDOFUN(wr_ch_pphelp) PSEUDOFUNSS(wr_ss_pphelp)
PSEUDOFUN(rd_ch_buff_in)
PSEUDOFUN(wr_ch_buff_out)
#ifdef PRINTER
PSEUDOFUN(wr_ch_printer)
#endif
#ifdef PIPES
PSEUDOFUN(rd_ch_pipe_in)
PSEUDOFUN(wr_ch_pipe_out) PSEUDOFUNSS(wr_ss_pipe_out)
#endif
#ifdef X11SOCKETS
PSEUDOFUN(rd_ch_x11socket) PSEUDOFUN(wr_ch_x11socket) PSEUDOFUNSS(wr_ss_x11socket) PSEUDOFUN(rd_by_x11socket) PSEUDOFUN(wr_by_x11socket)
#endif
#ifdef SOCKET_STREAMS
PSEUDOFUN(rd_ch_socket) PSEUDOFUN(wr_ch_socket) PSEUDOFUNSS(wr_ss_socket) PSEUDOFUN(rd_by_socket) PSEUDOFUN(wr_by_socket)
#endif
#ifdef GENERIC_STREAMS
PSEUDOFUN(rd_ch_generic) PSEUDOFUN(wr_ch_generic) PSEUDOFUNSS(wr_ss_generic) PSEUDOFUN(rd_by_generic) PSEUDOFUN(wr_by_generic)
#endif

