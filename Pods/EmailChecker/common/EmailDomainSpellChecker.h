#ifndef _DOMAINEMAILSPELLCHECKER_H_
#define _DOMAINEMAILSPELLCHECKER_H_

#include <string>
#include <unordered_set>

class EmailDomainSpellChecker {
private:
    std::unordered_set<std::string> mModel;

private:
    void known(const std::unordered_set<std::string> &words, std::unordered_set<std::string> &results);
    void edits(const std::string &word, std::unordered_set<std::string> &results);
    std::string suggest(const std::string &word);
    std::string extractDomain(const std::string &word);

public:
    EmailDomainSpellChecker();
    std::string suggestDomainCorrection(const std::string &word);
};

#endif
