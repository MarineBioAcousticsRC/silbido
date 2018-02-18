
package tonals;

public class CQBankBehavior extends FilterBankBehavior
{
    private double linBinHz;
    private double maxGapHz;
    private double[] centerFrequencies;
    private double[] bandwidths;
    
    private int maxGapBins;
    
    public CQBankBehavior(){}
    
    public CQBankBehavior(double linBinHz, double maxGapHz, double[] centerFrequencies, double[] bandwidths)
    {
        super(maxGapHz);
        this.linBinHz = linBinHz;
        this.maxGapHz = maxGapHz;
        this.centerFrequencies = centerFrequencies;
        this.bandwidths = bandwidths;
        
        maxGapBins = (int)Math.round(maxGapHz / linBinHz);
    }

    public double binHz(double inputFreq)
    {
        int filterIdx = findFilterIdx(inputFreq);
        return bandwidths[filterIdx];
    }
    
    public double lowerBound(double inputFreq)
    {
        int filterIdx = findFilterIdx(inputFreq);
        int lowerFilterIdx = filterIdx - maxGapBins;
        if (lowerFilterIdx < 0) { lowerFilterIdx = 0; }
        return centerFrequencies[lowerFilterIdx];
    }
    
    public double upperBound(double inputFreq)
    {
        int filterIdx = findFilterIdx(inputFreq);
        int upperFilterIdx = filterIdx + maxGapBins;
        if (upperFilterIdx > centerFrequencies.length-1) { upperFilterIdx = centerFrequencies.length-1; }
        return centerFrequencies[upperFilterIdx];
    }
    
    public boolean inRange(double freq1, double freq2)
    {
        return (freq2 >= this.lowerBound(freq1) &&
        freq2 <= this.upperBound(freq1));
    }
    
    public double maxGapHz(double inputFreq)
    {
        return upperBound(inputFreq) - lowerBound(inputFreq);
    }
    
    public FilterBankBehavior makeClone()
    {
        return new CQBankBehavior(this.linBinHz, this.maxGapHz, this.centerFrequencies.clone(), this.bandwidths.clone());
    }
    
    /* Find the index of the filter whose center frequency is closest to the
     * input frequency.
     */
    private int findFilterIdx(double inputFreq)
    {
        int filterIdx = 0;
        double difference = Double.POSITIVE_INFINITY;
        for (int i=0; i<centerFrequencies.length; i++)
        {
            if (Math.abs(centerFrequencies[i] - inputFreq) < difference)
            {
                filterIdx = i;
                difference = Math.abs(centerFrequencies[i] - inputFreq);
            }
            else
            {
                return filterIdx;
            }
        }
        return filterIdx;
    }
}