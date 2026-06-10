'use strict';

var dct = require('dct');

function extractPowerSpectrum (_a) {
    var ampSpectrum = _a.ampSpectrum;
    if (typeof ampSpectrum !== "object") {
        throw new TypeError();
    }
    var powerSpectrum = new Float32Array(ampSpectrum.length);
    for (var i = 0; i < powerSpectrum.length; i++) {
        powerSpectrum[i] = Math.pow(ampSpectrum[i], 2);
    }
    return powerSpectrum;
}

function extractMelBands (_a) {
    var ampSpectrum = _a.ampSpectrum, melFilterBank = _a.melFilterBank, bufferSize = _a.bufferSize;
    if (typeof ampSpectrum !== "object") {
        throw new TypeError("Valid ampSpectrum is required to generate melBands");
    }
    if (typeof melFilterBank !== "object") {
        throw new TypeError("Valid melFilterBank is required to generate melBands");
    }
    var powSpec = extractPowerSpectrum({ ampSpectrum: ampSpectrum });
    var numFilters = melFilterBank.length;
    var filtered = Array(numFilters);
    var loggedMelBands = new Float32Array(numFilters);
    for (var i = 0; i < loggedMelBands.length; i++) {
        filtered[i] = new Float32Array(bufferSize / 2);
        loggedMelBands[i] = 0;
        for (var j = 0; j < bufferSize / 2; j++) {
            //point-wise multiplication between power spectrum and filterbanks.
            filtered[i][j] = melFilterBank[i][j] * powSpec[j];
            //summing up all of the coefficients into one array
            loggedMelBands[i] += filtered[i][j];
        }
        //log each coefficient.
        loggedMelBands[i] = Math.log(loggedMelBands[i] + 1);
    }
    return Array.prototype.slice.call(loggedMelBands);
}

function mfcc (_a) {
    // Tutorial from:
    // http://practicalcryptography.com/miscellaneous/machine-learning
    // /guide-mel-frequency-cepstral-coefficients-mfccs/
    // @ts-ignore
    var ampSpectrum = _a.ampSpectrum, melFilterBank = _a.melFilterBank, numberOfMFCCCoefficients = _a.numberOfMFCCCoefficients, bufferSize = _a.bufferSize;
    var _numberOfMFCCCoefficients = Math.min(40, Math.max(1, numberOfMFCCCoefficients || 13));
    var numFilters = melFilterBank.length;
    if (numFilters < _numberOfMFCCCoefficients) {
        throw new Error("Insufficient filter bank for requested number of coefficients");
    }
    var loggedMelBandsArray = extractMelBands({
        ampSpectrum: ampSpectrum,
        melFilterBank: melFilterBank,
        bufferSize: bufferSize,
    });
    var mfccs = dct(loggedMelBandsArray).slice(0, _numberOfMFCCCoefficients);
    return mfccs;
}

module.exports = mfcc;
