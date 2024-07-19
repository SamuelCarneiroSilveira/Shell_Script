import syslog                                   

# Abrir uma conexão com o syslog
syslog.openlog(ident='my_program', logoption=syslog.LOG_PID | syslog.LOG_CONS)

# Enviar uma mensagem de log para o syslog
syslog.syslog(syslog.LOG_INFO, '#ERRO - logmessage')

# Fechar a conexão com o syslog
syslog.closelog()
