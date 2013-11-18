#include "EmailDomainSpellChecker.h"

const static std::unordered_set<std::string> sModel = {
    "yahoo.com", "google.com", "hotmail.com", "gmail.com", "me.com", "aol.com", "mac.com",
    "live.com", "comcast.net", "comcast.com", "googlemail.com", "msn.com", "hotmail.co.uk", "yahoo.co.uk",
    "facebook.com", "verizon.net", "sbcglobal.net", "att.net", "gmx.com", "mail.com", "outlook.com",
};

#pragma mark - Constructors and destructore

EmailDomainSpellChecker::EmailDomainSpellChecker() {
}

#pragma mark - Private methods

std::string EmailDomainSpellChecker::suggest(const std::string &word) {
    std::unordered_set<std::string> candidates;
    std::unordered_set<std::string> results;

    // word is not mispelled
    if (sModel.find(word) != sModel.end()) {
        return word;
    }

    // add edited and known words the results
    edits(word, results);
    known(results, candidates);

    if (candidates.size() > 0) {
        return *candidates.begin();
    }

    return "";
}

void EmailDomainSpellChecker::known(const std::unordered_set<std::string> &words,
                                    std::unordered_set<std::string> &results) {
    for (std::unordered_set<std::string>::const_iterator i = words.begin(); i != words.end(); i++) {
        if (sModel.find(*i) != sModel.end()) {
            results.insert(*i);
        }
    }
}

void EmailDomainSpellChecker::edits(const std::string &word, std::unordered_set<std::string> &results) {
    // deletes
    for (size_t i = 0; i < word.size(); i++) {
        results.insert(word.substr(0, i) + word.substr(i + 1));
    }
    // transposes
    for (size_t i = 0; i < word.size() - 1; i++) {
        results.insert(word.substr(0, i) + word[i + 1] + word[i] + word.substr(i + 2));
    }
    // replaces
    for (size_t i = 0; i < word.size(); i++) {
        for (char j = 'a'; j <= 'z'; ++j) {
            results.insert(word.substr(0, i) + j + word.substr(i + 1));
        }
    }
    // inserts
    for (size_t i = 0; i < word.size() + 1; i++) {
        for (char j = 'a'; j <= 'z'; ++j) {
            results.insert(word.substr(0, i) + j + word.substr(i));
        }
    }
}

#pragma mark - Public methods

std::string EmailDomainSpellChecker::suggestDomainCorrection(const std::string &emailAddress) {
    size_t atCharPosition = emailAddress.find('@');
    std::string extractedDomain = std::string(emailAddress.data() + atCharPosition + 1);
    // don't check domain name shorter than 1 char
    if (extractedDomain.size() <= 1) {
        return emailAddress;
    }
    std::string suggestion = suggest(extractedDomain);
    // If domain suggestion is the same as original, return original email address or not found
    if (suggestion.compare(extractedDomain) == 0 || suggestion.size() == 0) {
        return emailAddress;
    }
    // construct return string
    return emailAddress.substr(0, atCharPosition + 1) + suggestion;
}
