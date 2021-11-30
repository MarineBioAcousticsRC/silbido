/*
 *   XML serializing/deserializing of MATLAB arrays
 *   author: Ladislav Dobrovsky   (dobrovsky@fme.vutbr.cz, ladislav.dobrovsky@gmail.com)
 *   
 *   last change: 2015-02-27
 *
 *   compile with mexit.m
 *
 *   2015-02-28     Peter van den Biggelaar    Handle structure similar to xml_load from Matlab Central
 *   2015-03-05     Ladislav Dobrovsky         Function handles load/save  (str2func, func2str) 
 *   2015-03-05     Peter van den Biggelaar    Support N-dimension arrays
 */

#include "tinyxml2.h"

#include <mex.h>

#include <string>
#include <sstream>
#include <math.h>   // fabs

using namespace tinyxml2;
using namespace std;


struct ExportOptions
{
    char *doubleFloatingFormat; // if NULL use default
    char *singleFloatingFormat; // if NULL use default
    bool storeSize, storeClass;
    ExportOptions():
        singleFloatingFormat(NULL),
        doubleFloatingFormat(NULL),
        storeSize(true), storeClass(true)
    {}
    
    ~ExportOptions()
    {
        if(singleFloatingFormat)
            mxFree(singleFloatingFormat);
        if(doubleFloatingFormat)
            mxFree(doubleFloatingFormat);
    }
};


const char * getFormatingString(mxClassID classID, const char *className, const char *singleFloatingFormat, const char *doubleFloatingFormat);
mxClassID getClassByName(const char *name);
mwSize * getDimensions(const char *sizeAttribute, mwSize *ndim, size_t *numel);
XMLNode * add(XMLNode *parent, const mxArray *data_MA, const char *nodeName, ExportOptions *options);

template<typename T>
XMLNode * add(XMLNode *parent, T const * const data, const mxArray *data_MA, mxClassID classID, const char *nodeName, ExportOptions *options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );
    
    size_t   ndim = mxGetNumberOfDimensions(data_MA);
    const mwSize *dims = mxGetDimensions(data_MA);
    size_t  numel = mxGetNumberOfElements(data_MA);
    if(numel!=1 && options->storeSize)
    {
        char *sizeStr = (char *)mxMalloc((ndim*10 + 1)*sizeof(char));  // max number of characters for unsigned equals 9 + space
        int pos = 0;
        for(unsigned n=0; n<ndim-1; n++)
        {
            pos += sprintf(sizeStr+pos, "%u ",
			   static_cast<unsigned int>(dims[n]));           
        }
        sprintf(sizeStr+pos, "%u",
		static_cast<unsigned int>(dims[ndim-1]));   // last size without a space  
        element->SetAttribute("size", sizeStr);
        mxFree(sizeStr);
    }
    
    if(options->storeClass)
    {
        element->SetAttribute("type", mxGetClassName(data_MA));
    }

    const char *frmStr = getFormatingString(classID, mxGetClassName(data_MA), options->singleFloatingFormat, options->doubleFloatingFormat);
    string str;
       
    static char format[256];
    sprintf(format, "%s ", frmStr);
    
    static char tmpS[1024];
    for(unsigned i=0; i < numel; i++)
    {
        if(i == numel-1)
            // print last value without trailing space
            sprintf(format, "%s", frmStr);
        
        sprintf(tmpS, format, data[i]);
        str += tmpS;
    }
    
    element->InsertFirstChild( doc->NewText(str.c_str()));
    
    return element;
}


XMLNode * addStruct(XMLNode *parent, const mxArray *aStruct, const char *nodeName, ExportOptions *options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );

    size_t   ndim = mxGetNumberOfDimensions(aStruct);
    const mwSize *dims = mxGetDimensions(aStruct);
    size_t  numel = mxGetNumberOfElements(aStruct);
    bool writeIndexes = false;
    
    if(numel!=1 && options->storeSize)
    {
        char *sizeStr = (char *)mxMalloc((ndim*10 + 1)*sizeof(char));  // max number of characters for unsigned equals 9 + space
        int pos = 0;
        for(unsigned n=0; n<ndim-1; n++)
        {
	  pos += sprintf(sizeStr+pos, "%u ",
			 static_cast<unsigned int>(dims[n]));           
        }
	// last size without a space  
        sprintf(sizeStr+pos, "%u",
		static_cast<unsigned int>(dims[ndim-1]));   
        element->SetAttribute("size", sizeStr);
        writeIndexes = true;
        mxFree(sizeStr);
    }
    
    if(options->storeClass)
    {
        element->SetAttribute("type", mxGetClassName(aStruct));
    }

    if(numel==0)
        return element; // nothing to do here...

    unsigned nFields = mxGetNumberOfFields(aStruct);
    
    XMLElement *fieldElement=0;
    
    for(unsigned idx=0; idx < numel; idx++)  // loop over indexes
    {
        for(unsigned fN = 0; fN < nFields; fN++)  // loop over fields
        {
            const char *fieldName = mxGetFieldNameByNumber(aStruct, fN);

            mxArray *field = mxGetField(aStruct, idx, fieldName);

            if(field)
                fieldElement = add(element, field, fieldName, options)->ToElement();
            else
            {
                fieldElement = doc->NewElement(fieldName);
                element->InsertEndChild(fieldElement);
                if(options->storeClass)
                    fieldElement->SetAttribute("type", "double");
                if(options->storeSize)
                    fieldElement->SetAttribute("size", "0 0");
            }

            if(writeIndexes)
                fieldElement->SetAttribute("idx", idx+1);
        }
    }
    
    return element;
}


XMLNode * addCell(XMLNode *parent, const mxArray *aCell, const char *nodeName, ExportOptions *options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );
     
    mwSize   ndim = mxGetNumberOfDimensions(aCell);
    const mwSize *dims = mxGetDimensions(aCell);
    size_t  numel = mxGetNumberOfElements(aCell);
    bool writeIndexes = false;   
    if(numel!=1 && options->storeSize)
    {
        char *sizeStr = (char *)mxMalloc((ndim*10 + 1)*sizeof(char));  // max number of characters for unsigned equals 9 + space
        int pos = 0;
        for(unsigned n=0; n<ndim-1; n++)
        {
	  pos += sprintf(sizeStr+pos, "%u ", 
			 static_cast<unsigned int>(dims[n]));           
        }
        sprintf(sizeStr+pos, "%u",
		static_cast<unsigned int>(dims[ndim-1]));   // last size without a space  
        element->SetAttribute("size", sizeStr);
        writeIndexes = true;
        mxFree(sizeStr);
    }
    
    if(options->storeClass)
    {
        element->SetAttribute("type", mxGetClassName(aCell));
    }
    
    if(numel==0)
        return element; // nothing to do here...

    XMLElement *cellElement=0;
    
    for(unsigned idx=0; idx < numel; idx++)
    {
        mxArray *cell = mxGetCell(aCell, idx);

        if(cell)
            cellElement = add(element, cell, "item", options)->ToElement();
        else
        {
            cellElement = doc->NewElement("item");
            element->InsertEndChild(cellElement);
            if(options->storeClass)
                cellElement->SetAttribute("type", "double");
            if(options->storeSize)
                cellElement->SetAttribute("size", "0 0");
        }

        if(writeIndexes)
            cellElement->SetAttribute("idx", idx+1);
    }
    
    return element;
}


XMLNode *addChar(XMLNode *parent, char const * const data, const mxArray * aString, const char *nodeName, ExportOptions *options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );

    mwSize   ndim = mxGetNumberOfDimensions(aString);
    const mwSize *dims = mxGetDimensions(aString);
    size_t  numel = mxGetNumberOfElements(aString); 
    if(options->storeSize)
    {
        char *sizeStr = (char *)mxMalloc((ndim*10 + 1)*sizeof(char));  // max number of characters for unsigned equals 9 + space
        int pos = 0;
        for(unsigned n=0; n<ndim-1; n++)
        {
	  pos += sprintf(sizeStr+pos, "%u ", 
static_cast<unsigned int>(dims[n]));           
        }
        sprintf(sizeStr+pos, "%u",
		static_cast<unsigned int>(dims[ndim-1]));   // last size without a space  
        element->SetAttribute("size", sizeStr);
        mxFree(sizeStr);
    }
    
    if(options->storeClass)
    {
        element->SetAttribute("type", mxGetClassName(aString));
    }
    
    char *stringCopy = mxArrayToString(aString);
    
    //printf("string len = %u ; m = %u, n = %u; content=\"%c\"\n", len, (unsigned)mxGetM(aString), (unsigned)mxGetN(aString), data[0]/*string(data, len).c_str()*/);
    
    element->InsertFirstChild( doc->NewText( stringCopy ) );
    mxFree(stringCopy);
    
    return element;
}


XMLNode *addFunctionHandle(XMLNode *parent, const mxArray *fHandle, const char *nodeName, ExportOptions *options)
{
    XMLDocument *doc = parent->GetDocument();
    XMLElement *element = doc->NewElement(nodeName);
    parent->InsertEndChild( element );
    
    if(options->storeClass)
    {
        element->SetAttribute("type", mxGetClassName(fHandle));
    }
    else
    {
        mexPrintf("[XML LOAD WARNING] function handle being saved without class specification, will become a string!\n");
    }
    
    mxArray *lhs[1];
    mxArray *rhs[1] = {const_cast<mxArray*>(fHandle)};
    
    mexCallMATLAB(1, lhs, 1, rhs, "func2str");
	char *stringCopy=mxArrayToString(lhs[0]);
    element->InsertFirstChild( doc->NewText( stringCopy ) );
    mxFree(stringCopy);
    return element;
}


XMLNode * add(XMLNode *parent, const mxArray *data_MA, const char *nodeName, ExportOptions *options)
{
    void const * const data=mxGetData(data_MA);
    mxClassID classID = mxGetClassID(data_MA);
    switch(classID)
    {
        case mxCELL_CLASS: return addCell(parent, data_MA, nodeName, options);
        case mxSTRUCT_CLASS: return addStruct(parent, data_MA, nodeName, options);
        case mxLOGICAL_CLASS: return add(parent, (mxLogical*)data, data_MA, classID, nodeName, options);
        case mxDOUBLE_CLASS: return add(parent, (double*)data, data_MA, classID, nodeName, options);
        case mxSINGLE_CLASS: return add(parent, (float*)data, data_MA, classID, nodeName, options);

        case mxINT8_CLASS: return add(parent, (signed char*)data, data_MA, classID, nodeName, options);
        case mxUINT8_CLASS: return add(parent, (unsigned char*)data, data_MA, classID, nodeName, options);
        case mxINT16_CLASS: return add(parent, (short*)data, data_MA, classID, nodeName, options);
        case mxUINT16_CLASS: return add(parent, (unsigned short*)data, data_MA, classID, nodeName, options);
        case mxINT32_CLASS: return add(parent, (int*)data, data_MA, classID, nodeName, options);
        case mxUINT32_CLASS: return add(parent, (unsigned int*)data, data_MA, classID, nodeName, options);
        
        case mxCHAR_CLASS: return addChar(parent, (const char * const)data,  data_MA, nodeName, options);
        
        //mxINT64_CLASS,
        //mxUINT64_CLASS,

        case mxFUNCTION_CLASS: return addFunctionHandle(parent, data_MA, nodeName, options);
        
        default:
        {
            char tmpS[512];
            sprintf(tmpS, "unsupported class to save in xml format: %s\n", mxGetClassName(data_MA));
            mexErrMsgTxt(tmpS);
        }            
    }
    return NULL;
}

mxArray *extract(const XMLElement *element);

// string
mxArray *extractChar(const XMLElement *element)
{
    mxArray *aString = mxCreateString(element->GetText());

    mwSize ndim=0;
    size_t numel=0;
    const char *sizeAttribute=element->Attribute( "size" );
    mwSize *dims = getDimensions(sizeAttribute, &ndim, &numel);
    
    if(sizeAttribute)
    {
        // reshape into specified size
        // note: character arrays may look a bit weird in the xml-file
        //       because strings are stored column-wise. This functionality
        //       is equivalent with xml_save/xml_load
        if(mxGetNumberOfElements(aString) != numel)
            mexErrMsgTxt("number of characters does not match specified size");
 
        mxSetDimensions(aString, dims, ndim);    
    }
    mxFree(dims);
    
    return aString;
}


// structures
// mxCreateStructArray N-D NOT SUPPORTED
// mxArray *mxCreateStructMatrix(mwSize m, mwSize n, int nfields, const char **fieldnames);

mxArray *extractStruct(const XMLElement *element)
{
    mwSize ndim=0;
    size_t numel=0;
    const char *sizeAttribute=element->Attribute( "size" );
    size_t *dims = getDimensions(sizeAttribute, &ndim, &numel);

    if(!sizeAttribute)
    {
        // determine size by counting children and checking "idx" attribute
        numel=0;
        const XMLElement *structElement = element->FirstChildElement();
        while(structElement)
        {
            numel += 1;  // Increment index (start 
            unsigned int idx = static_cast<unsigned int>(numel);
            structElement->QueryUnsignedAttribute("idx", &idx);
            structElement = structElement->NextSiblingElement();
        }
        dims[0] = 1;        // 1 row
        dims[1] = numel;    // numel columns
    }
       
    mxArray *theStruct = mxCreateStructArray(ndim, dims, 0, 0);
    mxFree(dims);
	if(!theStruct)
        mexErrMsgTxt("creating structure array failed.");
    
    if(numel)
    {
        unsigned *idx = NULL;
        unsigned max_idx = 1;
        const XMLElement *structElement=element->FirstChildElement();
        while(structElement)
        {
            const char *name = structElement->Value();
            if(!name)
                name="NO_NAME_STRUCT_FIELD";

            // add fieldname or increment idx for existing fieldname
            int fieldNumber = mxGetFieldNumber(theStruct, name);
            if(fieldNumber<0)
            {   // field does not exist; add field and initialize idx for this field
                fieldNumber=mxAddField(theStruct, name);
                if(fieldNumber<0)
                    mexErrMsgTxt("can't add field");
                
                // (re)allocate space for tracking indices for each field
                idx = (unsigned *)mxRealloc(idx, sizeof(unsigned)*(fieldNumber+1));
                idx[fieldNumber] = 1;
            }
            else
            {   // fieldname already exists
                
                // increment idx of this field
                idx[fieldNumber]++;
                    
                //  keep track of maximum idx
                if(idx[fieldNumber]>max_idx)
                    max_idx = idx[fieldNumber];
            }
            
            // get value of "idx" attribute. idx will be unchanged when attribute is not defined
            structElement->QueryUnsignedAttribute("idx", &(idx[fieldNumber]));
            if(idx[fieldNumber]>numel)
                mexErrMsgTxt("element idx > struct length");

            // set field value
            mxArray *fieldValue = extract(structElement);
            if(fieldValue)   
                mxSetFieldByNumber(theStruct, idx[fieldNumber]-1, fieldNumber, fieldValue); 
            else
                mexPrintf("[XML LOAD WARNING] struct field %s (idx %d) is corrupted\n", name, idx[fieldNumber]);

            structElement = structElement->NextSiblingElement();
        }

        if(max_idx<numel && !sizeAttribute)
        {
            // remove extra columns
            mxSetN(theStruct, max_idx);
        }
        
        mxFree(idx);
    }

    return theStruct;
}


// cells
mxArray *extractCell(const XMLElement *element)
{
    mwSize ndim=0;
    size_t numel=0;
    const char *sizeAttribute=element->Attribute( "size" );
    size_t *dims = getDimensions(sizeAttribute, &ndim, &numel);

    // count cells
    {
        unsigned len2=0;
        const XMLElement *cellElement = element->FirstChildElement("item");
        while(cellElement)
        {
            unsigned idx=len2+1; // idx range: 1...N
            cellElement->QueryUnsignedAttribute("idx", &idx);
            len2++;
            if(idx>len2+1)
                len2=idx;
            cellElement = cellElement->NextSiblingElement("item");
        }
        if(numel != len2)
        {
            ndim    = 2;
            dims[0] = 1;
            dims[1] = len2;
            numel   = len2;
            if(sizeAttribute)
                mexPrintf("[XML LOAD WARNING] cell array size specified, but the actual count differs\n");
        }
    }

    mxArray *theCell = mxCreateCellArray(ndim, dims);
    mxFree(dims);   
	if(!theCell)
        mexErrMsgTxt("creating cell array failed.");

    if(numel)
    {
        unsigned naturalOrder=0; // used if idx is not specified
        const XMLElement *cellElement = element->FirstChildElement("item");
        while(cellElement)
        {
            unsigned idx=naturalOrder+1; // idx range: 1...N
            cellElement->QueryUnsignedAttribute("idx", &idx);

            if(idx>numel)
                mexErrMsgTxt("element idx > cell length");

            mxArray *cellValue = extract(cellElement);
            if(cellValue)
                mxSetCell(theCell, idx-1, cellValue);
            else
                mexPrintf("[XML LOAD WARNING] cell (idx %d) is corrupted\n", idx);

            cellElement = cellElement->NextSiblingElement("item");
            naturalOrder++; 
        }
    }
       
    return theCell;	
}

template <typename T>
mxArray *extract(const XMLElement *element, mxClassID classID)
{
    //const char *fmtStr = getFormatingString(classID, "[extract, no className given]");
    
    mwSize ndim=0;
    size_t numel=0;
    const char *sizeAttribute=element->Attribute( "size" );
    size_t *dims = getDimensions(sizeAttribute, &ndim, &numel);
    
    mxArray *theMatrix = mxCreateNumericArray(ndim, dims, classID, mxREAL);
    mxFree(dims);
    
    if(numel)
    {
        T *elements = (T*)mxGetData(theMatrix);
        stringstream ss(element->GetText());
        for(unsigned idx=0; idx<numel; idx++)
        {
            if(classID == mxINT8_CLASS || classID == mxUINT8_CLASS)
            { // code path for 8bit integer number (char)
                int value;
                ss >> value; // string stream would extract ASCII value of a character, not whole number
                elements[idx] = T(value);
            }
            else
                ss >> elements[idx];
            
            if(ss.eof() && idx!=numel-1)
            {
                mexPrintf("[XML LOAD WARING] stringstream eof=%d, badbit=%d\n", (int)ss.eof(), (int)ss.bad());
                break;
            }
            
            if(ss.bad())
            {
                mexPrintf("[XML LOAD WARING] stringstream eof=%d, badbit=%d\n", (int)ss.eof(), (int)ss.bad());
                break;
            }
        }
        
    }
    return theMatrix;
}


mxArray *extractFunctionHandle(const XMLElement *element)
{
    mxArray *lhs[1], *rhs[1]={mxCreateString(element->GetText())};
    
    mexCallMATLAB(1, lhs, 1, rhs, "str2func");
    return lhs[0];
}    

    
mxArray *extract(const XMLElement *element)
{
    const char* classStr = element->Attribute("type");
    
    if(!classStr)    
    {
        // have children elements -> struct or cell
        if(element->FirstChildElement())
        {           
            // we need at least 2 consequtive 'item' elements to consider the element a cell array
            const XMLElement *itemElement=element->FirstChildElement("item");
            if(itemElement && itemElement->NextSiblingElement("item"))
                classStr="cell";
            else
                // otherwise it's a struct
                classStr="struct"; 
        }
        else // or else it's considered a string
            classStr="char";
    }
    
    mxClassID classID = getClassByName(classStr);

    switch(classID)
    {
        case mxCELL_CLASS: return extractCell(element);
        case mxSTRUCT_CLASS: return extractStruct(element);
        case mxLOGICAL_CLASS: return extract<mxLogical>(element, classID);
        case mxDOUBLE_CLASS: return extract<double>(element, classID);
        case mxSINGLE_CLASS: return extract<float>(element, classID);

        case mxINT8_CLASS: return extract<signed char>(element, classID);
        case mxUINT8_CLASS: return extract<unsigned char>(element, classID);
        case mxINT16_CLASS: return extract<short>(element, classID);
        case mxUINT16_CLASS: return extract<unsigned short>(element, classID);
        case mxINT32_CLASS: return extract<int>(element, classID);
        case mxUINT32_CLASS: return extract<unsigned int>(element, classID);
        
        case mxCHAR_CLASS: return extractChar(element);
        
        case mxFUNCTION_CLASS: return extractFunctionHandle(element);
        
        default:
        {
            string tmpS("unrecognized or unsupported class: ");
            tmpS+=classStr;
            mexErrMsgTxt(tmpS.c_str());
        }
    }
  
}

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    if(nrhs<2)
        mexErrMsgTxt("2 input required; tinyxml2_wrap(mode, filename, ...)\n");
    
    const mxArray *mode_MA = prhs[0];
	const mxArray *filename_MA = prhs[1];
    
    char * modeString = mxArrayToString(mode_MA);
    char * filename = mxArrayToString(filename_MA);
    
    if(!modeString)
        mexErrMsgTxt("mode string error\n");
    if(!filename)
        mexErrMsgTxt("filename string error\n");
    
    if(!strcmp(modeString, "save"))
    {
        if(nrhs<3)
            mexErrMsgTxt("save mode requires 3rd input - data to save\n");
        const mxArray *data_MA = prhs[2];
        
        XMLDocument doc;
        
        ExportOptions options;
        if(nrhs>=4)
        {
            const mxArray *options_MA = prhs[3];
            if(!mxIsStruct(options_MA))
            {
                mexErrMsgTxt("save mode: options parameter must be a struct!\n");
            }
            
            mxArray *field = mxGetField(options_MA, 0, "fp_format_single");
            if(field)
            {
                if(!mxIsChar(field))
                {
                    mexErrMsgTxt("save mode: option fp_format_single must be char string!\n");
                }
                options.singleFloatingFormat = mxArrayToString(field);
            }

            field = mxGetField(options_MA, 0, "fp_format_double");
            if(field)
            {
                if(!mxIsChar(field))
                {
                    mexErrMsgTxt("save mode: option fp_format_double must be char string!\n");
                }
                options.doubleFloatingFormat = mxArrayToString(field);
            }
            
            field = mxGetField(options_MA, 0, "store_class");
            if(field)
            {
                if(!mxIsNumeric(field))
                {
                    mexErrMsgTxt("save mode: option store_class must be numeric!\n");
                }
                options.storeClass = fabs(mxGetScalar(field)) > 1e-6;
            }
            
            field = mxGetField(options_MA, 0, "store_size");
            if(field)
            {
                if(!mxIsNumeric(field))
                {
                    mexErrMsgTxt("save mode: option store_size must be numeric!\n");
                }
                options.storeSize = fabs(mxGetScalar(field)) > 1e-6;
            }
        }
        
        bool storeSize=true;
        bool storeClass=true;
        
        add(&doc, data_MA, "root", &options);

        doc.SaveFile(filename);
    }
    else if(!strcmp(modeString, "load"))
    {
        if(nlhs>1)
            mexErrMsgTxt("load mode requires only 1 input\n");
        
        XMLDocument doc;
        if (doc.LoadFile(filename) != XML_NO_ERROR)
        {
            mexErrMsgIdAndTxt("tinyxml2_wrap:load", "xml load: %s ; %s", doc.GetErrorStr1(), doc.GetErrorStr2());
        }
        
        const XMLElement *root = doc.FirstChildElement();
        
        if(!root)
            mexErrMsgTxt("no elements!\n");
        
        plhs[0] = extract(root);
    }   
    else
        mexErrMsgTxt("unknown mode\n");
}

mxClassID getClassByName(const char *name)
{
    if(!strcmp("char", name))
        return mxCHAR_CLASS;
    else if(!strcmp("single", name))
        return mxSINGLE_CLASS;
    else if(!strcmp("double", name))
        return mxDOUBLE_CLASS;
    else if(!strcmp("struct", name))
        return mxSTRUCT_CLASS;
    else if(!strcmp("cell", name))
        return mxCELL_CLASS;
    else if(!strcmp("int8", name))
        return mxINT8_CLASS;
    else if(!strcmp("uint8", name))
        return mxUINT8_CLASS;
    else if(!strcmp("int16", name))
        return mxINT16_CLASS;
    else if(!strcmp("uint16", name))
        return mxUINT16_CLASS;
    else if(!strcmp("int32", name))
        return mxINT32_CLASS;
    else if(!strcmp("uint32", name))
        return mxUINT32_CLASS;
    else if(!strcmp("int64", name))
        return mxINT64_CLASS;
    else if(!strcmp("uint64", name))
        return mxUINT64_CLASS;
    else if(!strcmp("logical", name))
        return mxLOGICAL_CLASS;
    else if(!strcmp("function_handle", name))
        return mxFUNCTION_CLASS;
        
    return mxUNKNOWN_CLASS;
}

const char * getFormatingString(mxClassID classID, const char *className, const char *singleFloatingFormat, const char *doubleFloatingFormat)
{
    static char errorBuf[512];
    
    switch(classID)
    {
        case mxDOUBLE_CLASS: return doubleFloatingFormat ? doubleFloatingFormat : "%lg";
        case mxSINGLE_CLASS: return singleFloatingFormat ? singleFloatingFormat : "%g";
        case mxLOGICAL_CLASS:
            switch(sizeof(mxLogical))
            {
                case sizeof(int):
                    return "%d";
                case sizeof(char):
                    return "%hhd";
                case sizeof(short):
                    return "%hd";
            }
        case mxINT8_CLASS: return "%hhd";
        case mxUINT8_CLASS: return "%hhu";
        case mxINT16_CLASS: return "%hd";
        case mxUINT16_CLASS: return "%hu";
        case mxINT32_CLASS: return "%d";
        case mxUINT32_CLASS: return "%u";
        
        default:
            sprintf(errorBuf, "[ERROR: can't get format string for class %s]", className);
            return errorBuf;
    }
}


mwSize * getDimensions(const char *sizeAttribute, mwSize *ndim, size_t *numel)
/*
 * Get number of dimensions and size per dimension from "size" attribute in element.
 *
 * Return pointer to an array with the size of each dimension.          
 * Space for dims will be allocated and needs to be freed with mxFree
 * when not needed anymore.
 *
 * sizeAttribute : string with sizes per dimension
 * *ndim         : number of dimensions
 *                 will be at least 2 
 * *numel        : number of elements
 *
 * When size attribute equals NULL, also space will be allocated and
 * ndim=2, numel=1 and size in each dimension equals 1.
 */
{
    *ndim = 0;
    *numel = 1;
    mwSize *dimSize = static_cast<mwSize *>(mxMalloc(2*sizeof(mwSize)));
    if(sizeAttribute)
    {
        // read size of each dimension until it fails
        const char * size_ptr = sizeAttribute;
        int pos;
        int r;
        unsigned size;
        while( (r=sscanf(size_ptr, "%u%n", &size, &pos))>0 )    
        {
            size_ptr += pos;
            (*ndim)++;            
            dimSize = static_cast<mwSize *>(mxRealloc(dimSize, *ndim * sizeof(mwSize)));
            dimSize[*ndim-1] = size;
            *numel *= size;
        }
        
        if(r!=EOF)
            // scanning sizeAttribute stopped on error
            mexErrMsgTxt("size attribute corrupted");  
        
        if(*ndim==0)
            mexErrMsgTxt("size attribute was empty");
            
        if(*ndim==1)
        {
            // if only one dimension size is specified return a row vector
            dimSize[1] = dimSize[0];
            dimSize[0] = 1;
            *ndim = 2;
        }    
    }
    else
    {
        // if no dimension size is specified return size 1x1
        dimSize[0] = 1;
        dimSize[1] = 1;
        *ndim = 2;
    }
    
    return dimSize;
}

