
package tonals;

public abstract class FilterBankBehavior
{	
    double maxGapHz;
    
    public FilterBankBehavior(){}
    
    public FilterBankBehavior(double maxGapHz)
    {
        this.maxGapHz = maxGapHz;
    }
    

    abstract public double binHz(double inputFreq);
    abstract public double maxGapHz(double inputFreq);
    abstract public double lowerBound(double inputFreq);
    abstract public double upperBound(double inputFreq);
    abstract public boolean inRange(double freq1, double freq2);
    abstract public FilterBankBehavior makeClone();
}