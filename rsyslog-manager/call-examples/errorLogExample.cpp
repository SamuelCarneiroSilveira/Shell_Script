#include <syslog.h>

int main() {
    // Abrir uma conexão com o syslog
    openlog("my_program", LOG_PID | LOG_CONS, LOG_USER);

    // Enviar uma mensagem de log para o syslog
    syslog(LOG_INFO, "#ERRO - logmessage");

    // Fechar a conexão com o syslog
    closelog();

    return 0;
}
