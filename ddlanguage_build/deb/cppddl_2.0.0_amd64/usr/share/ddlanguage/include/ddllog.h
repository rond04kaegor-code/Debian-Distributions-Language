#ifndef DDLLOG_H
#define DDLLOG_H
#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <string>
namespace ddl {
class Logger {
    std::shared_ptr<spdlog::logger> log;
public:
    Logger(const std::string& n,const std::string& f="ddl.log"){log=spdlog::basic_logger_mt(n,f);}
    void info(const std::string& m){log->info(m);}
    void warn(const std::string& m){log->warn(m);}
    void error(const std::string& m){log->error(m);}
};
inline Logger* log_create(const std::string& n,const std::string& f="ddl.log"){return new Logger(n,f);}
}
#endif
