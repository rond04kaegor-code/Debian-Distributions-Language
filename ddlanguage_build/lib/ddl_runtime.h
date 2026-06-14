#ifndef DDL_RUNTIME_H
#define DDL_RUNTIME_H
#include <iostream>
#include <string>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <ctime>
#include <thread>
#include <chrono>
namespace ddl {
inline void say(const std::string& t) { std::cout << t << std::endl; }
inline void whisper(const std::string& t) { std::cout << t << "..." << std::endl; }
inline void rainbow(const std::string& t) { std::cout << t << std::endl; }
inline void box(const std::string& t) { std::string b="+"+std::string(t.length()+2,'-')+"+"; std::cout<<b<<"\n| "<<t<<" |\n"<<b<<std::endl; }
inline void wait(double s) { std::this_thread::sleep_for(std::chrono::milliseconds((int)(s*1000))); }
inline void clear() { system("clear"); }
inline void write_file(const std::string& n, const std::string& c) { std::ofstream f(n); f<<c; }
}
#endif
