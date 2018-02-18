
package tonals;

public class LinearBankBehavior extends FilterBankBehavior
{
    private double binHz;
    
    public LinearBankBehavior(){}
    
    public LinearBankBehavior(double binHz, double maxGapHz)
    {
        super(maxGapHz);
        this.binHz = binHz;
    }

    public double binHz(double inputFreq)
    {
        return binHz;
    }
    
    public double maxGapHz(double inputFreq)
    {
        return maxGapHz;
    }
    
    public double lowerBound(double inputFreq)
    {
        double output = inputFreq - this.maxGapHz;
        return output;
    }
    
    public double upperBound(double inputFreq)
    {
        double output = inputFreq + this.maxGapHz;
        return output;
    }
    
    public boolean inRange(double freq1, double freq2)
    {
        return (freq2 >= this.lowerBound(freq1) && 
               freq2 <= this.upperBound(freq1));
    }
    
    public FilterBankBehavior makeClone()
    {
        return new LinearBankBehavior(this.binHz, this.maxGapHz);
    }
}