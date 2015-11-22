/*
Original code by Lee Thomason (www.grinninglizard.com)

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any
damages arising from the use of this software.

Permission is granted to anyone to use this software for any
purpose, including commercial applications, and to alter it and
redistribute it freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must
not claim that you wrote the original software. If you use this
software in a product, an acknowledgment in the product documentation
would be appreciated but is not required.

2. Altered source versions must be plainly marked as such, and
must not be misrepresented as being the original software.

3. This notice may not be removed or altered from any source
distribution.
*/

#ifndef TINYXML2_INCLUDED
#define TINYXML2_INCLUDED

#include <cctype>
#include <climits>
#include <cstdio>
#include <cstring>
#include <cstdarg>

#if 1
	#include <cstdio>
	#include <cstdlib>
	#include <new>
#else
	#include <string.h>
	#include <stdlib.h>
	#include <stdio.h>
	#include <ctype.h>
	#include <new>
	#include <stdarg.h>
#endif


/* 
   TODO: intern strings instead of allocation.
*/
/*
	gcc: g++ -Wall tinyxml2.cpp xmltest.cpp -o gccxmltest.exe
*/

#if defined( _DEBUG ) || defined( DEBUG ) || defined (__DEBUG__)
	#ifndef DEBUG
		#define DEBUG
	#endif
#endif


#if defined(DEBUG)
        #if defined(_MSC_VER)
                #define TIXMLASSERT( x )           if ( !(x)) { __debugbreak(); } //if ( !(x)) WinDebugBreak()
        #elif defined (ANDROID_NDK)
                #include <android/log.h>
                #define TIXMLASSERT( x )           if ( !(x)) { __android_log_assert( "assert", "grinliz", "ASSERT in '%s' at %d.", __FILE__, __LINE__ ); }
        #else
                #include <assert.h>
                #define TIXMLASSERT                assert
        #endif
#else
        #define TIXMLASSERT( x )           {}
#endif


#if defined(_MSC_VER) && (_MSC_VER >= 1400 )
	// Microsoft visual studio, version 2005 and higher.
	/*int _snprintf_s(
	   char *buffer,
	   size_t sizeOfBuffer,
	   size_t count,	
	   const char *format [,
		  argument] ... 
	);*/
	inline int TIXML_SNPRINTF( char* buffer, size_t size, const char* format, ... ) {
	    va_list va;
		va_start( va, format );
		int result = vsnprintf_s( buffer, size, _TRUNCATE, format, va );
	    va_end( va );
		return result;
	}
	#define TIXML_SSCANF   sscanf_s
#else
	// GCC version 3 and higher
	//#warning( "Using sn* functions." )
	#define TIXML_SNPRINTF snprintf
	#define TIXML_SSCANF   sscanf
#endif

static const int TIXML2_MAJOR_VERSION = 0;
static const int TIXML2_MINOR_VERSION = 9;
static const int TIXML2_PATCH_VERSION = 4;

namespace tinyxml2
{
class XMLDocument;
class XMLElement;
class XMLAttribute;
class XMLComment;
class XMLNode;
class XMLText;
class XMLDeclaration;
class XMLUnknown;

class XMLPrinter;

/*
	A class that wraps strings. Normally stores the start and end
	pointers into the XML file itself, and will apply normalization
	and entity translation if actually read. Can also store (and memory
	manage) a traditional char[]
*/
class StrPair
{
public:
	enum {
		NEEDS_ENTITY_PROCESSING			= 0x01,
		NEEDS_NEWLINE_NORMALIZATION		= 0x02,

		TEXT_ELEMENT		= NEEDS_ENTITY_PROCESSING | NEEDS_NEWLINE_NORMALIZATION,
		TEXT_ELEMENT_LEAVE_ENTITIES		= NEEDS_NEWLINE_NORMALIZATION,
		ATTRIBUTE_NAME		= 0,
		ATTRIBUTE_VALUE		= NEEDS_ENTITY_PROCESSING | NEEDS_NEWLINE_NORMALIZATION,
		ATTRIBUTE_VALUE_LEAVE_ENTITIES		= NEEDS_NEWLINE_NORMALIZATION,
		COMMENT				= NEEDS_NEWLINE_NORMALIZATION
	};

	StrPair() : flags( 0 ), start( 0 ), end( 0 ) {}
	~StrPair();

	void Set( char* _start, char* _end, int _flags ) {
		Reset();
		this->start = _start; this->end = _end; this->flags = _flags | NEEDS_FLUSH;
	}
	const char* GetStr();
	bool Empty() const { return start == end; }

	void SetInternedStr( const char* str ) { Reset(); this->start = const_cast<char*>(str); }
	void SetStr( const char* str, int flags=0 );

	char* ParseText( char* in, const char* endTag, int strFlags );
	char* ParseName( char* in );


private:
	void Reset();

	enum {
		NEEDS_FLUSH = 0x100,
		NEEDS_DELETE = 0x200
	};

	// After parsing, if *end != 0, it can be set to zero.
	int flags;
	char* start;	
	char* end;
};


/*
	A dynamic array of Plain Old Data. Doesn't support constructors, etc.
	Has a small initial memory pool, so that low or no usage will not
	cause a call to new/delete
*/
template <class T, int INIT>
class DynArray
{
public:
	DynArray< T, INIT >() 
	{
		mem = pool;
		allocated = INIT;
		size = 0;
	}
	~DynArray()
	{
		if ( mem != pool ) {
			delete mem;
		}
	}
	void Push( T t )
	{
		EnsureCapacity( size+1 );
		mem[size++] = t;
	}

	T* PushArr( int count )
	{
		EnsureCapacity( size+count );
		T* ret = &mem[size];
		size += count;
		return ret;
	}
	T Pop() {
		return mem[--size];
	}
	void PopArr( int count ) 
	{
		TIXMLASSERT( size >= count );
		size -= count;
	}

	bool Empty() const					{ return size == 0; }
	T& operator[](int i)				{ TIXMLASSERT( i>= 0 && i < size ); return mem[i]; }
	const T& operator[](int i) const	{ TIXMLASSERT( i>= 0 && i < size ); return mem[i]; }
	int Size() const					{ return size; }
	int Capacity() const				{ return allocated; }
	const T* Mem() const				{ return mem; }
	T* Mem()							{ return mem; }


private:
	void EnsureCapacity( int cap ) {
		if ( cap > allocated ) {
			int newAllocated = cap * 2;
			T* newMem = new T[newAllocated];
			memcpy( newMem, mem, sizeof(T)*size );	// warning: not using constructors, only works for PODs
			if ( mem != pool ) delete [] mem;
			mem = newMem;
			allocated = newAllocated;
		}
	}

	T* mem;
	T pool[INIT];
	int allocated;		// objects allocated
	int size;			// number objects in use
};


/*
	Parent virtual class a a pool for fast allocation
	and deallocation of objects.
*/
class MemPool
{
public:
	MemPool() {}
	virtual ~MemPool() {}

	virtual int ItemSize() const = 0;
	virtual void* Alloc() = 0;
	virtual void Free( void* ) = 0; 
};


/*
	Template child class to create pools of the correct type.
*/
template< int SIZE >
class MemPoolT : public MemPool
{
public:
	MemPoolT() : root(0), currentAllocs(0), nAllocs(0), maxAllocs(0)	{}
	~MemPoolT() {
		// Delete the blocks.
		for( int i=0; i<blockPtrs.Size(); ++i ) {
			delete blockPtrs[i];
		}
	}

	virtual int ItemSize() const	{ return SIZE; }
	int CurrentAllocs() const		{ return currentAllocs; }

	virtual void* Alloc() {
		if ( !root ) {
			// Need a new block.
			Block* block = new Block();
			blockPtrs.Push( block );

			for( int i=0; i<COUNT-1; ++i ) {
				block->chunk[i].next = &block->chunk[i+1];
			}
			block->chunk[COUNT-1].next = 0;
			root = block->chunk;
		}
		void* result = root;
		root = root->next;

		++currentAllocs;
		if ( currentAllocs > maxAllocs ) maxAllocs = currentAllocs;
		nAllocs++;
		return result;
	}
	virtual void Free( void* mem ) {
		if ( !mem ) return;
		--currentAllocs;
		Chunk* chunk = (Chunk*)mem;
		memset( chunk, 0xfe, sizeof(Chunk) );
		chunk->next = root;
		root = chunk;
	}
	void Trace( const char* name ) {
		printf( "Mempool %s watermark=%d [%dk] current=%d size=%d nAlloc=%d blocks=%d\n",
				 name, maxAllocs, maxAllocs*SIZE/1024, currentAllocs, SIZE, nAllocs, blockPtrs.Size() );
	}

private:
	enum { COUNT = 1024/SIZE };
	union Chunk {
		Chunk* next;
		char mem[SIZE];
	};
	struct Block {
		Chunk chunk[COUNT];
	};
	DynArray< Block*, 10 > blockPtrs;
	Chunk* root;

	int currentAllocs;
	int nAllocs;
	int maxAllocs;
};



/**
	Implements the interface to the "Visitor pattern" (see the Accept() method.)
	If you call the Accept() method, it requires being passed a XMLVisitor
	class to handle callbacks. For nodes that contain other nodes (Document, Element)
	you will get called with a VisitEnter/VisitExit pair. Nodes that are always leaves
	are simply called with Visit().

	If you return 'true' from a Visit method, recursive parsing will continue. If you return
	false, <b>no children of this node or its sibilings</b> will be Visited.

	All flavors of Visit methods have a default implementation that returns 'true' (continue 
	visiting). You need to only override methods that are interesting to you.

	Generally Accept() is called on the TiXmlDocument, although all nodes suppert Visiting.

	You should never change the document from a callback.

	@sa XMLNode::Accept()
*/
class XMLVisitor
{
public:
	virtual ~XMLVisitor() {}

	/// Visit a document.
	virtual bool VisitEnter( const XMLDocument& /*doc*/ )			{ return true; }
	/// Visit a document.
	virtual bool VisitExit( const XMLDocument& /*doc*/ )			{ return true; }

	/// Visit an element.
	virtual bool VisitEnter( const XMLElement& /*element*/, const XMLAttribute* /*firstAttribute*/ )	{ return true; }
	/// Visit an element.
	virtual bool VisitExit( const XMLElement& /*element*/ )			{ return true; }

	/// Visit a declaration
	virtual bool Visit( const XMLDeclaration& /*declaration*/ )		{ return true; }
	/// Visit a text node
	virtual bool Visit( const XMLText& /*text*/ )					{ return true; }
	/// Visit a comment node
	virtual bool Visit( const XMLComment& /*comment*/ )				{ return true; }
	/// Visit an unknown node
	virtual bool Visit( const XMLUnknown& /*unknown*/ )				{ return true; }
};


/*
	Utility functionality.
*/
class XMLUtil
{
public:
	// Anything in the high order range of UTF-8 is assumed to not be whitespace. This isn't 
	// correct, but simple, and usually works.
	static const char* SkipWhiteSpace( const char* p )	{ while( !IsUTF8Continuation(*p) && isspace( *p ) ) { ++p; } return p; }
	static char* SkipWhiteSpace( char* p )				{ while( !IsUTF8Continuation(*p) && isspace( *p ) ) { ++p; } return p; }

	inline static bool StringEqual( const char* p, const char* q, int nChar=INT_MAX )  {
		int n = 0;
		if ( p == q ) {
			return true;
		}
		while( *p && *q && *p == *q && n<nChar ) {
			++p; ++q; ++n;
		}
		if ( (n == nChar) || ( *p == 0 && *q == 0 ) ) {
			return true;
		}
		return false;
	}
	inline static int IsUTF8Continuation( const char p ) { return p & 0x80; }
	inline static int IsAlphaNum( unsigned char anyByte )	{ return ( anyByte < 128 ) ? isalnum( anyByte ) : 1; }
	inline static int IsAlpha( unsigned char anyByte )		{ return ( anyByte < 128 ) ? isalpha( anyByte ) : 1; }

	static const char* ReadBOM( const char* p, bool* hasBOM );
	// p is the starting location,
	// the UTF-8 value of the entity will be placed in value, and length filled in.
	static const char* GetCharacterRef( const char* p, char* value, int* length );
	static void ConvertUTF32ToUTF8( unsigned long input, char* output, int* length );
};


/** XMLNode is a base class for every object that is in the
	XML Document Object Model (DOM), except XMLAttributes.
	Nodes have siblings, a parent, and children which can
	be navigated. A node is always in a XMLDocument.
	The type of a XMLNode can be queried, and it can 
	be cast to its more defined type.

	An XMLDocument allocates memory for all its Nodes.
	When the XMLDocument gets deleted, all its Nodes
	will also be deleted.

	@verbatim
	A Document can contain:	Element	(container or leaf)
							Comment (leaf)
							Unknown (leaf)
							Declaration( leaf )

	An Element can contain:	Element (container or leaf)
							Text	(leaf)
							Attributes (not on tree)
							Comment (leaf)
							Unknown (leaf)

	@endverbatim
*/
class XMLNode
{
	friend class XMLDocument;
	friend class XMLElement;
public:

	/// Get the XMLDocument that owns this XMLNode.
	const XMLDocument* GetDocument() const	{ return document; }
	/// Get the XMLDocument that owns this XMLNode.
	XMLDocument* GetDocument()				{ return document; }

	virtual XMLElement*		ToElement()		{ return 0; }	///< Safely cast to an Element, or null.
	virtual XMLText*		ToText()		{ return 0; }	///< Safely cast to Text, or null.
	virtual XMLComment*		ToComment()		{ return 0; }	///< Safely cast to a Comment, or null.
	virtual XMLDocument*	ToDocument()	{ return 0; }	///< Safely cast to a Document, or null.
	virtual XMLDeclaration*	ToDeclaration()	{ return 0; }	///< Safely cast to a Declaration, or null.
	virtual XMLUnknown*		ToUnknown()		{ return 0; }	///< Safely cast to an Unknown, or null.

	virtual const XMLElement*		ToElement() const		{ return 0; }
	virtual const XMLText*			ToText() const			{ return 0; }
	virtual const XMLComment*		ToComment() const		{ return 0; }
	virtual const XMLDocument*		ToDocument() const		{ return 0; }
	virtual const XMLDeclaration*	ToDeclaration() const	{ return 0; }
	virtual const XMLUnknown*		ToUnknown() const		{ return 0; }

	/** The meaning of 'value' changes for the specific type.
		@verbatim
		Document:	empy
		Element:	name of the element
		Comment:	the comment text
		Unknown:	the tag contents
		Text:		the text string
		@endverbatim
	*/
	const char* Value() const			{ return value.GetStr(); }
	/** Set the Value of an XML node.
		@sa Value()
	*/
	void SetValue( const char* val, bool staticMem=false );

	/// Get the parent of this node on the DOM.
	const XMLNode*	Parent() const			{ return parent; }
	XMLNode* Parent()						{ return parent; }

	/// Returns true if this node has no children.
	bool NoChildren() const					{ return !firstChild; }

	/// Get the first child node, or null if none exists.
	const XMLNode*  FirstChild() const		{ return firstChild; }
	XMLNode*		FirstChild()			{ return firstChild; }
	/** Get the first child element, or optionally the first child
	    element with the specified name.
	*/
	const XMLElement* FirstChildElement( const char* value=0 ) const;
	XMLElement* FirstChildElement( const char* _value=0 )	{ return const_cast<XMLElement*>(const_cast<const XMLNode*>(this)->FirstChildElement( _value )); }

	/// Get the last child node, or null if none exists.
	const XMLNode*	LastChild() const						{ return lastChild; }
	XMLNode*		LastChild()								{ return const_cast<XMLNode*>(const_cast<const XMLNode*>(this)->LastChild() ); }

	/** Get the last child element or optionally the last child
	    element with the specified name.
	*/
	const XMLElement* LastChildElement( const char* value=0 ) const;
	XMLElement* LastChildElement( const char* _value=0 )	{ return const_cast<XMLElement*>(const_cast<const XMLNode*>(this)->LastChildElement(_value) ); }
	
	/// Get the previous (left) sibling node of this node.
	const XMLNode*	PreviousSibling() const					{ return prev; }
	XMLNode*	PreviousSibling()							{ return prev; }

	/// Get the previous (left) sibling element of this node, with an opitionally supplied name.
	const XMLElement*	PreviousSiblingElement( const char* value=0 ) const ;
	XMLElement*	PreviousSiblingElement( const char* _value=0 ) { return const_cast<XMLElement*>(const_cast<const XMLNode*>(this)->PreviousSiblingElement( _value ) ); }
	
	/// Get the next (right) sibling node of this node.
	const XMLNode*	NextSibling() const						{ return next; }
	XMLNode*	NextSibling()								{ return next; }
		
	/// Get the next (right) sibling element of this node, with an opitionally supplied name.
	const XMLElement*	NextSiblingElement( const char* value=0 ) const;
 	XMLElement*	NextSiblingElement( const char* _value=0 )	{ return const_cast<XMLElement*>(const_cast<const XMLNode*>(this)->NextSiblingElement( _value ) ); }

	/**
		Add a child node as the last (right) child.
	*/
	XMLNode* InsertEndChild( XMLNode* addThis );

	XMLNode* LinkEndChild( XMLNode* addThis )	{ return InsertEndChild( addThis ); }
	/**
		Add a child node as the first (left) child.
	*/
	XMLNode* InsertFirstChild( XMLNode* addThis );
	/**
		Add a node after the specified child node.
	*/
	XMLNode* InsertAfterChild( XMLNode* afterThis, XMLNode* addThis );
	
	/**
		Delete all the children of this node.
	*/
	void DeleteChildren();

	/**
		Delete a child of this node.
	*/
	void DeleteChild( XMLNode* node );

	/**
		Make a copy of this node, but not its children.
		You may pass in a Document pointer that will be
		the owner of the new Node. If the 'document' is 
		null, then the node returned will be allocated
		from the current Document. (this->GetDocument())

		Note: if called on a XMLDocument, this will return null.
	*/
	virtual XMLNode* ShallowClone( XMLDocument* document ) const = 0;

	/**
		Test if 2 nodes are the same, but don't test children.
		The 2 nodes do not need to be in the same Document.

		Note: if called on a XMLDocument, this will return false.
	*/
	virtual bool ShallowEqual( const XMLNode* compare ) const = 0;

	/** Accept a hierchical visit the nodes in the TinyXML DOM. Every node in the 
		XML tree will be conditionally visited and the host will be called back
		via the TiXmlVisitor interface.

		This is essentially a SAX interface for TinyXML. (Note however it doesn't re-parse
		the XML for the callbacks, so the performance of TinyXML is unchanged by using this
		interface versus any other.)

		The interface has been based on ideas from:

		- http://www.saxproject.org/
		- http://c2.com/cgi/wiki?HierarchicalVisitorPattern 

		Which are both good references for "visiting".

		An example of using Accept():
		@verbatim
		TiXmlPrinter printer;
		tinyxmlDoc.Accept( &printer );
		const char* xmlcstr = printer.CStr();
		@endverbatim
	*/
	virtual bool Accept( XMLVisitor* visitor ) const = 0;

	// internal
	virtual char* ParseDeep( char*, StrPair* );

protected:
	XMLNode( XMLDocument* );
	virtual ~XMLNode();
	XMLNode( const XMLNode& );	// not supported
	void operator=( const XMLNode& );	// not supported
	
	XMLDocument*	document;
	XMLNode*		parent;
	mutable StrPair	value;

	XMLNode*		firstChild;
	XMLNode*		lastChild;

	XMLNode*		prev;
	XMLNode*		next;

private:
	MemPool*		memPool;
	void Unlink( XMLNode* child );
};


/** XML text.

	Note that a text node can have child element nodes, for example:
	@verbatim
	<root>This is <b>bold</b></root>
	@endverbatim

	A text node can have 2 ways to output the next. "normal" output 
	and CDATA. It will default to the mode it was parsed from the XML file and
	you generally want to leave it alone, but you can change the output mode with 
	SetCDATA() and query it with CDATA().
*/
class XMLText : public XMLNode
{
	friend class XMLBase;
	friend class XMLDocument;
public:
	virtual bool Accept( XMLVisitor* visitor ) const;

	virtual XMLText*	ToText()			{ return this; }
	virtual const XMLText*	ToText() const	{ return this; }

	/// Declare whether this should be CDATA or standard text.
	void SetCData( bool _isCData )			{ this->isCData = _isCData; }
	/// Returns true if this is a CDATA text element.
	bool CData() const						{ return isCData; }

	char* ParseDeep( char*, StrPair* endTag );
	virtual XMLNode* ShallowClone( XMLDocument* document ) const;
	virtual bool ShallowEqual( const XMLNode* compare ) const;


protected:
	XMLText( XMLDocument* doc )	: XMLNode( doc ), isCData( false )	{}
	virtual ~XMLText()												{}
	XMLText( const XMLText& );	// not supported
	void operator=( const XMLText& );	// not supported

private:
	bool isCData;
};


/** An XML Comment. */
class XMLComment : public XMLNode
{
	friend class XMLDocument;
public:
	virtual XMLComment*	ToComment()					{ return this; }
	virtual const XMLComment* ToComment() const		{ return this; }

	virtual bool Accept( XMLVisitor* visitor ) const;

	char* ParseDeep( char*, StrPair* endTag );
	virtual XMLNode* ShallowClone( XMLDocument* document ) const;
	virtual bool ShallowEqual( const XMLNode* compare ) const;

protected:
	XMLComment( XMLDocument* doc );
	virtual ~XMLComment();
	XMLComment( const XMLComment& );	// not supported
	void operator=( const XMLComment& );	// not supported

private:
};


/** In correct XML the declaration is the first entry in the file.
	@verbatim
		<?xml version="1.0" standalone="yes"?>
	@endverbatim

	TinyXML2 will happily read or write files without a declaration,
	however.

	The text of the declaration isn't interpreted. It is parsed
	and written as a string.
*/
class XMLDeclaration : public XMLNode
{
	friend class XMLDocument;
public:
	virtual XMLDeclaration*	ToDeclaration()					{ return this; }
	virtual const XMLDeclaration* ToDeclaration() const		{ return this; }

	virtual bool Accept( XMLVisitor* visitor ) const;

	char* ParseDeep( char*, StrPair* endTag );
	virtual XMLNode* ShallowClone( XMLDocument* document ) const;
	virtual bool ShallowEqual( const XMLNode* compare ) const;

protected:
	XMLDeclaration( XMLDocument* doc );
	virtual ~XMLDeclaration();
	XMLDeclaration( const XMLDeclaration& );	// not supported
	void operator=( const XMLDeclaration& );	// not supported
};


/** Any tag that tinyXml doesn't recognize is saved as an
	unknown. It is a tag of text, but should not be modified.
	It will be written back to the XML, unchanged, when the file
	is saved.

	DTD tags get thrown into TiXmlUnknowns.
*/
class XMLUnknown : public XMLNode
{
	friend class XMLDocument;
public:
	virtual XMLUnknown*	ToUnknown()					{ return this; }
	virtual const XMLUnknown* ToUnknown() const		{ return this; }

	virtual bool Accept( XMLVisitor* visitor ) const;

	char* ParseDeep( char*, StrPair* endTag );
	virtual XMLNode* ShallowClone( XMLDocument* document ) const;
	virtual bool ShallowEqual( const XMLNode* compare ) const;

protected:
	XMLUnknown( XMLDocument* doc );
	virtual ~XMLUnknown();
	XMLUnknown( const XMLUnknown& );	// not supported
	void operator=( const XMLUnknown& );	// not supported
};


enum {
	XML_NO_ERROR = 0,
	XML_SUCCESS = 0,

	XML_NO_ATTRIBUTE,
	XML_WRONG_ATTRIBUTE_TYPE,

	XML_ERROR_FILE_NOT_FOUND,
	XML_ERROR_FILE_COULD_NOT_BE_OPENED,
	XML_ERROR_ELEMENT_MISMATCH,
	XML_ERROR_PARSING_ELEMENT,
	XML_ERROR_PARSING_ATTRIBUTE,
	XML_ERROR_IDENTIFYING_TAG,
	XML_ERROR_PARSING_TEXT,
	XML_ERROR_PARSING_CDATA,
	XML_ERROR_PARSING_COMMENT,
	XML_ERROR_PARSING_DECLARATION,
	XML_ERROR_PARSING_UNKNOWN,
	XML_ERROR_EMPTY_DOCUMENT,
	XML_ERROR_MISMATCHED_ELEMENT,
	XML_ERROR_PARSING
};


/** An attribute is a name-value pair. Elements have an arbitrary
	number of attributes, each with a unique name.

	@note The attributes are not XMLNodes. You may only query the
	Next() attribute in a list.
*/
class XMLAttribute
{
	friend class XMLElement;
public:
	const char* Name() const { return name.GetStr(); }			///< The name of the attribute.
	const char* Value() const { return value.GetStr(); }		///< The value of the attribute.
	const XMLAttribute* Next() const { return next; }			///< The next attribute in the list.

	/** IntAttribute interprets the attribute as an integer, and returns the value.
	    If the value isn't an integer, 0 will be returned. There is no error checking;
		use QueryIntAttribute() if you need error checking.
	*/
	int		 IntValue() const				{ int i=0;		QueryIntValue( &i );		return i; }
	/// Query as an unsigned integer. See IntAttribute()
	unsigned UnsignedValue() const			{ unsigned i=0; QueryUnsignedValue( &i );	return i; }
	/// Query as a boolean. See IntAttribute()
	bool	 BoolValue() const				{ bool b=false; QueryBoolValue( &b );		return b; }
	/// Query as a double. See IntAttribute()
	double 	 DoubleValue() const			{ double d=0;	QueryDoubleValue( &d );		return d; }
	/// Query as a float. See IntAttribute()
	float	 FloatValue() const				{ float f=0;	QueryFloatValue( &f );		return f; }

	/** QueryIntAttribute interprets the attribute as an integer, and returns the value
		in the provided paremeter. The function will return XML_NO_ERROR on success,
		and XML_WRONG_ATTRIBUTE_TYPE if the conversion is not successful.
	*/
	int QueryIntValue( int* value ) const;
	/// See QueryIntAttribute
	int QueryUnsignedValue( unsigned int* value ) const;
	/// See QueryIntAttribute
	int QueryBoolValue( bool* value ) const;
	/// See QueryIntAttribute
	int QueryDoubleValue( double* value ) const;
	/// See QueryIntAttribute
	int QueryFloatValue( float* value ) const;

	/// Set the attribute to a string value.
	void SetAttribute( const char* value );
	/// Set the attribute to value.
	void SetAttribute( int value );
	/// Set the attribute to value.
	void SetAttribute( unsigned value );
	/// Set the attribute to value.
	void SetAttribute( bool value );
	/// Set the attribute to value.
	void SetAttribute( double value );
	/// Set the attribute to value.
	void SetAttribute( float value );

private:
	enum { BUF_SIZE = 200 };

	XMLAttribute() : next( 0 ) {}
	virtual ~XMLAttribute()	{}
	XMLAttribute( const XMLAttribute& );	// not supported
	void operator=( const XMLAttribute& );	// not supported
	void SetName( const char* name );

	char* ParseDeep( char* p, bool processEntities );

	mutable StrPair name;
	mutable StrPair value;
	XMLAttribute* next;
	MemPool* memPool;
};


/** The element is a container class. It has a value, the element name,
	and can contain other elements, text, comments, and unknowns.
	Elements also contain an arbitrary number of attributes.
*/
class XMLElement : public XMLNode
{
	friend class XMLBase;
	friend class XMLDocument;
public:
	/// Get the name of an element (which is the Value() of the node.)
	const char* Name() const		{ return Value(); }
	/// Set the name of the element.
	void SetName( const char* str, bool staticMem=false )	{ SetValue( str, staticMem ); }

	virtual XMLElement* ToElement()				{ return this; }
	virtual const XMLElement* ToElement() const { return this; }
	virtual bool Accept( XMLVisitor* visitor ) const;

	/** Given an attribute name, Attribute() returns the value
		for the attribute of that name, or null if none 
		exists. For example:

		@verbatim
		const char* value = ele->Attribute( "foo" );
		@endverbatim

		The 'value' parameter is normally null. However, if specified, 
		the attribute will only be returned if the 'name' and 'value' 
		match. This allow you to write code:

		@verbatim
		if ( ele->Attribute( "foo", "bar" ) ) callFooIsBar();
		@endverbatim

		rather than:
		@verbatim
		if ( ele->Attribute( "foo" ) ) {
			if ( strcmp( ele->Attribute( "foo" ), "bar" ) == 0 ) callFooIsBar();
		}
		@endverbatim
	*/
	const char* Attribute( const char* name, const char* value=0 ) const;

	/** Given an attribute name, IntAttribute() returns the value
		of the attribute interpreted as an integer. 0 will be
		returned if there is an error. For a method with error 
		checking, see QueryIntAttribute()
	*/
	int		 IntAttribute( const char* name ) const		{ int i=0;		QueryIntAttribute( name, &i );		return i; }
	/// See IntAttribute()
	unsigned UnsignedAttribute( const char* name ) const{ unsigned i=0; QueryUnsignedAttribute( name, &i ); return i; }
	/// See IntAttribute()
	bool	 BoolAttribute( const char* name ) const	{ bool b=false; QueryBoolAttribute( name, &b );		return b; }
	/// See IntAttribute()
	double 	 DoubleAttribute( const char* name ) const	{ double d=0;	QueryDoubleAttribute( name, &d );		return d; }
	/// See IntAttribute()
	float	 FloatAttribute( const char* name ) const	{ float f=0;	QueryFloatAttribute( name, &f );		return f; }

	/** Given an attribute name, QueryIntAttribute() returns 
		XML_NO_ERROR, XML_WRONG_ATTRIBUTE_TYPE if the conversion
		can't be performed, or XML_NO_ATTRIBUTE if the attribute
		doesn't exist. If successful, the result of the conversion
		will be written to 'value'. If not successful, nothing will
		be written to 'value'. This allows you to provide default
		value:

		@verbatim
		int value = 10;
		QueryIntAttribute( "foo", &value );		// if "foo" isn't found, value will still be 10
		@endverbatim
	*/
	int QueryIntAttribute( const char* name, int* _value ) const					{ const XMLAttribute* a = FindAttribute( name ); if ( !a ) return XML_NO_ATTRIBUTE; return a->QueryIntValue( _value ); } 
	/// See QueryIntAttribute()
	int QueryUnsignedAttribute( const char* name, unsigned int* _value ) const	{ const XMLAttribute* a = FindAttribute( name ); if ( !a ) return XML_NO_ATTRIBUTE; return a->QueryUnsignedValue( _value ); }
	/// See QueryIntAttribute()
	int QueryBoolAttribute( const char* name, bool* _value ) const				{ const XMLAttribute* a = FindAttribute( name ); if ( !a ) return XML_NO_ATTRIBUTE; return a->QueryBoolValue( _value ); }
	/// See QueryIntAttribute()
	int QueryDoubleAttribute( const char* name, double* _value ) const			{ const XMLAttribute* a = FindAttribute( name ); if ( !a ) return XML_NO_ATTRIBUTE; return a->QueryDoubleValue( _value ); }
	/// See QueryIntAttribute()
	int QueryFloatAttribute( const char* name, float* _value ) const				{ const XMLAttribute* a = FindAttribute( name ); if ( !a ) return XML_NO_ATTRIBUTE; return a->QueryFloatValue( _value ); }

	/// Sets the named attribute to value.
	void SetAttribute( const char* name, const char* _value )	{ XMLAttribute* a = FindOrCreateAttribute( name ); a->SetAttribute( _value ); }
	/// Sets the named attribute to value.
	void SetAttribute( const char* name, int _value )			{ XMLAttribute* a = FindOrCreateAttribute( name ); a->SetAttribute( _value ); }
	/// Sets the named attribute to value.
	void SetAttribute( const char* name, unsigned _value )		{ XMLAttribute* a = FindOrCreateAttribute( name ); a->SetAttribute( _value ); }
	/// Sets the named attribute to value.
	void SetAttribute( const char* name, bool _value )			{ XMLAttribute* a = FindOrCreateAttribute( name ); a->SetAttribute( _value ); }
	/// Sets the named attribute to value.
	void SetAttribute( const char* name, double _value )			{ XMLAttribute* a = FindOrCreateAttribute( name ); a->SetAttribute( _value ); }

	/**
		Delete an attribute.
	*/
	void DeleteAttribute( const char* name );

	/// Return the first attribute in the list.
	const XMLAttribute* FirstAttribute() const { return rootAttribute; }
	/// Query a specific attribute in the list.
	const XMLAttribute* FindAttribute( const char* name ) const;

	/** Convenience function for easy access to the text inside an element. Although easy
		and concise, GetText() is limited compared to getting the TiXmlText child
		and accessing it directly.
	
		If the first child of 'this' is a TiXmlText, the GetText()
		returns the character string of the Text node, else null is returned.

		This is a convenient method for getting the text of simple contained text:
		@verbatim
		<foo>This is text</foo>
		const char* str = fooElement->GetText();
		@endverbatim

		'str' will be a pointer to "This is text". 
		
		Note that this function can be misleading. If the element foo was created from
		this XML:
		@verbatim
		<foo><b>This is text</b></foo> 
		@endverbatim

		then the value of str would be null. The first child node isn't a text node, it is
		another element. From this XML:
		@verbatim
		<foo>This is <b>text</b></foo> 
		@endverbatim
		GetText() will return "This is ".
	*/
	const char* GetText() const;

	// internal:
	enum {
		OPEN,		// <foo>
		CLOSED,		// <foo/>
		CLOSING		// </foo>
	};
	int ClosingType() const { return closingType; }
	char* ParseDeep( char* p, StrPair* endTag );
	virtual XMLNode* ShallowClone( XMLDocument* document ) const;
	virtual bool ShallowEqual( const XMLNode* compare ) const;

private:
	XMLElement( XMLDocument* doc );
	virtual ~XMLElement();
	XMLElement( const XMLElement& );	// not supported
	void operator=( const XMLElement& );	// not supported

	XMLAttribute* FindAttribute( const char* name );
	XMLAttribute* FindOrCreateAttribute( const char* name );
	//void LinkAttribute( XMLAttribute* attrib );
	char* ParseAttributes( char* p );

	int closingType;
	// The attribute list is ordered; there is no 'lastAttribute'
	// because the list needs to be scanned for dupes before adding
	// a new attribute.
	XMLAttribute* rootAttribute;
};


/** A document binds together all the functionality. 
	It can be saved, loaded, and printed to the screen.
	All Nodes are connected and allocated to a Document.
	If the Document is deleted, all its Nodes are also deleted.
*/
class XMLDocument : public XMLNode
{
	friend class XMLElement;
public:
	/// constructor
	XMLDocument( bool processEntities = true ); 
	~XMLDocument();

	virtual XMLDocument* ToDocument()				{ return this; }
	virtual const XMLDocument* ToDocument() const	{ return this; }

	/**
		Parse an XML file from a character string.
		Returns XML_NO_ERROR (0) on success, or
		an errorID.
	*/
	int Parse( const char* xml );
	
	/**
		Load an XML file from disk.
		Returns XML_NO_ERROR (0) on success, or
		an errorID.
	*/	
	int LoadFile( const char* filename );
	
	/**
		Load an XML file from disk. You are responsible
		for providing and closing the FILE*.

		Returns XML_NO_ERROR (0) on success, or
		an errorID.
	*/	
	int LoadFile( FILE* );
	
	/**
		Save the XML file to disk.
		Returns XML_NO_ERROR (0) on success, or
		an errorID.
	*/
	int SaveFile( const char* filename );

	/**
		Save the XML file to disk.  You are responsible
		for providing and closing the FILE*.

		Returns XML_NO_ERROR (0) on success, or
		an errorID.
	*/
	int SaveFile( FILE* );

	bool ProcessEntities() const						{ return processEntities; }

	/**
		Returns true if this document has a leading Byte Order Mark of UTF8.
	*/
	bool HasBOM() const { return writeBOM; }

	/** Return the root element of DOM. Equivalent to FirstChildElement().
	    To get the first node, use FirstChild().
	*/
	XMLElement* RootElement()				{ return FirstChildElement(); }
	const XMLElement* RootElement() const	{ return FirstChildElement(); }

	/** Print the Document. If the Printer is not provided, it will
	    print to stdout. If you provide Printer, this can print to a file:
		@verbatim
		XMLPrinter printer( fp );
		doc.Print( &printer );
		@endverbatim

		Or you can use a printer to print to memory:
		@verbatim
		XMLPrinter printer;
		doc->Print( &printer );
		// printer.CStr() has a const char* to the XML
		@endverbatim
	*/
	void Print( XMLPrinter* streamer=0 );
	virtual bool Accept( XMLVisitor* visitor ) const;

	/**
		Create a new Element associated with
		this Document. The memory for the Element
		is managed by the Document.
	*/
	XMLElement* NewElement( const char* name );
	/**
		Create a new Comment associated with
		this Document. The memory for the Comment
		is managed by the Document.
	*/
	XMLComment* NewComment( const char* comment );
	/**
		Create a new Text associated with
		this Document. The memory for the Text
		is managed by the Document.
	*/
	XMLText* NewText( const char* text );
	/**
		Create a new Declaration associated with
		this Document. The memory for the object
		is managed by the Document.
	*/
	XMLDeclaration* NewDeclaration( const char* text );
	/**
		Create a new Unknown associated with
		this Document. The memory for the object
		is managed by the Document.
	*/
	XMLUnknown* NewUnknown( const char* text );

	/**
		Delete a node associated with this documented.
		It will be unlinked from the DOM.
	*/
	void DeleteNode( XMLNode* node )	{ node->parent->DeleteChild( node ); }

	void SetError( int error, const char* str1, const char* str2 );
	
	/// Return true if there was an error parsing the document.
	bool Error() const { return errorID != XML_NO_ERROR; }
	/// Return the errorID.
	int  ErrorID() const { return errorID; }
	/// Return a possibly helpful diagnostic location or string.
	const char* GetErrorStr1() const { return errorStr1; }
	/// Return possibly helpful secondary diagnostic location or string.
	const char* GetErrorStr2() const { return errorStr2; }
	/// If there is an error, print it to stdout
	void PrintError() const;

	// internal
	char* Identify( char* p, XMLNode** node );

	virtual XMLNode* ShallowClone( XMLDocument* /*document*/ ) const	{ return 0; }
	virtual bool ShallowEqual( const XMLNode* /*compare*/ ) const	{ return false; }

private:
	XMLDocument( const XMLDocument& );	// not supported
	void operator=( const XMLDocument& );	// not supported
	void InitDocument();

	bool writeBOM;
	bool processEntities;
	int errorID;
	const char* errorStr1;
	const char* errorStr2;
	char* charBuffer;

	MemPoolT< sizeof(XMLElement) >	elementPool;
	MemPoolT< sizeof(XMLAttribute) > attributePool;
	MemPoolT< sizeof(XMLText) >		textPool;
	MemPoolT< sizeof(XMLComment) >	commentPool;
};


/**
	A XMLHandle is a class that wraps a node pointer with null checks; this is
	an incredibly useful thing. Note that XMLHandle is not part of the TinyXML
	DOM structure. It is a separate utility class.

	Take an example:
	@verbatim
	<Document>
		<Element attributeA = "valueA">
			<Child attributeB = "value1" />
			<Child attributeB = "value2" />
		</Element>
	<Document>
	@endverbatim

	Assuming you want the value of "attributeB" in the 2nd "Child" element, it's very 
	easy to write a *lot* of code that looks like:

	@verbatim
	XMLElement* root = document.FirstChildElement( "Document" );
	if ( root )
	{
		XMLElement* element = root->FirstChildElement( "Element" );
		if ( element )
		{
			XMLElement* child = element->FirstChildElement( "Child" );
			if ( child )
			{
				XMLElement* child2 = child->NextSiblingElement( "Child" );
				if ( child2 )
				{
					// Finally do something useful.
	@endverbatim

	And that doesn't even cover "else" cases. XMLHandle addresses the verbosity
	of such code. A XMLHandle checks for null pointers so it is perfectly safe 
	and correct to use:

	@verbatim
	XMLHandle docHandle( &document );
	XMLElement* child2 = docHandle.FirstChild( "Document" ).FirstChild( "Element" ).FirstChild().NextSibling().ToElement();
	if ( child2 )
	{
		// do something useful
	@endverbatim

	Which is MUCH more concise and useful.

	It is also safe to copy handles - internally they are nothing more than node pointers.
	@verbatim
	XMLHandle handleCopy = handle;
	@endverbatim

	See also XMLConstHandle, which is the same as XMLHandle, but operates on const objects.
*/
class XMLHandle
{
public:
	/// Create a handle from any node (at any depth of the tree.) This can be a null pointer.
	XMLHandle( XMLNode* _node )												{ node = _node; }
	/// Create a handle from a node.
	XMLHandle( XMLNode& _node )												{ node = &_node; }
	/// Copy constructor
	XMLHandle( const XMLHandle& ref )										{ node = ref.node; }
	/// Assignment
	XMLHandle operator=( const XMLHandle& ref )								{ node = ref.node; return *this; }

	/// Get the first child of this handle.
	XMLHandle FirstChild() 													{ return XMLHandle( node ? node->FirstChild() : 0 ); }
	/// Get the first child element of this handle.
	XMLHandle FirstChildElement( const char* value=0 )						{ return XMLHandle( node ? node->FirstChildElement( value ) : 0 ); }
	/// Get the last child of this handle.
	XMLHandle LastChild()													{ return XMLHandle( node ? node->LastChild() : 0 ); }
	/// Get the last child element of this handle.
	XMLHandle LastChildElement( const char* _value=0 )						{ return XMLHandle( node ? node->LastChildElement( _value ) : 0 ); }
	/// Get the previous sibling of this handle.
	XMLHandle PreviousSibling()												{ return XMLHandle( node ? node->PreviousSibling() : 0 ); }
	/// Get the previous sibling element of this handle.
	XMLHandle PreviousSiblingElement( const char* _value=0 )				{ return XMLHandle( node ? node->PreviousSiblingElement( _value ) : 0 ); }
	/// Get the next sibling of this handle.
	XMLHandle NextSibling()													{ return XMLHandle( node ? node->NextSibling() : 0 ); }		
	/// Get the next sibling element of this handle.
	XMLHandle NextSiblingElement( const char* _value=0 )					{ return XMLHandle( node ? node->NextSiblingElement( _value ) : 0 ); }

	/// Safe cast to XMLNode. This can return null.
	XMLNode* ToNode()							{ return node; } 
	/// Safe cast to XMLElement. This can return null.
	XMLElement* ToElement() 					{ return ( ( node && node->ToElement() ) ? node->ToElement() : 0 ); }
	/// Safe cast to XMLText. This can return null.
	XMLText* ToText() 							{ return ( ( node && node->ToText() ) ? node->ToText() : 0 ); }
	/// Safe cast to XMLUnknown. This can return null.
	XMLUnknown* ToUnknown() 					{ return ( ( node && node->ToUnknown() ) ? node->ToUnknown() : 0 ); }
	/// Safe cast to XMLDeclaration. This can return null.
	XMLDeclaration* ToDeclaration() 			{ return ( ( node && node->ToDeclaration() ) ? node->ToDeclaration() : 0 ); }

private:
	XMLNode* node;
};


/**
	A variant of the XMLHandle class for working with const XMLNodes and Documents. It is the
	same in all regards, except for the 'const' qualifiers. See XMLHandle for API.
*/
class XMLConstHandle
{
public:
	XMLConstHandle( const XMLNode* _node )											{ node = _node; }
	XMLConstHandle( const XMLNode& _node )											{ node = &_node; }
	XMLConstHandle( const XMLConstHandle& ref )										{ node = ref.node; }

	XMLConstHandle operator=( const XMLConstHandle& ref )							{ node = ref.node; return *this; }

	const XMLConstHandle FirstChild() const											{ return XMLConstHandle( node ? node->FirstChild() : 0 ); }
	const XMLConstHandle FirstChildElement( const char* value=0 ) const				{ return XMLConstHandle( node ? node->FirstChildElement( value ) : 0 ); }
	const XMLConstHandle LastChild()	const										{ return XMLConstHandle( node ? node->LastChild() : 0 ); }
	const XMLConstHandle LastChildElement( const char* _value=0 ) const				{ return XMLConstHandle( node ? node->LastChildElement( _value ) : 0 ); }
	const XMLConstHandle PreviousSibling() const									{ return XMLConstHandle( node ? node->PreviousSibling() : 0 ); }
	const XMLConstHandle PreviousSiblingElement( const char* _value=0 ) const		{ return XMLConstHandle( node ? node->PreviousSiblingElement( _value ) : 0 ); }
	const XMLConstHandle NextSibling() const										{ return XMLConstHandle( node ? node->NextSibling() : 0 ); }
	const XMLConstHandle NextSiblingElement( const char* _value=0 ) const			{ return XMLConstHandle( node ? node->NextSiblingElement( _value ) : 0 ); }


	const XMLNode* ToNode() const				{ return node; } 
	const XMLElement* ToElement() const			{ return ( ( node && node->ToElement() ) ? node->ToElement() : 0 ); }
	const XMLText* ToText() const				{ return ( ( node && node->ToText() ) ? node->ToText() : 0 ); }
	const XMLUnknown* ToUnknown() const			{ return ( ( node && node->ToUnknown() ) ? node->ToUnknown() : 0 ); }
	const XMLDeclaration* ToDeclaration() const	{ return ( ( node && node->ToDeclaration() ) ? node->ToDeclaration() : 0 ); }

private:
	const XMLNode* node;
};


/**
	Printing functionality. The XMLPrinter gives you more
	options than the XMLDocument::Print() method.

	It can:
	-# Print to memory.
	-# Print to a file you provide
	-# Print XML without a XMLDocument.

	Print to Memory

	@verbatim
	XMLPrinter printer;
	doc->Print( &printer );
	SomeFunctior( printer.CStr() );
	@endverbatim

	Print to a File
	
	You provide the file pointer.
	@verbatim
	XMLPrinter printer( fp );
	doc.Print( &printer );
	@endverbatim

	Print without a XMLDocument

	When loading, an XML parser is very useful. However, sometimes
	when saving, it just gets in the way. The code is often set up
	for streaming, and constructing the DOM is just overhead.

	The Printer supports the streaming case. The following code
	prints out a trivially simple XML file without ever creating
	an XML document.

	@verbatim
	XMLPrinter printer( fp );
	printer.OpenElement( "foo" );
	printer.PushAttribute( "foo", "bar" );
	printer.CloseElement();
	@endverbatim
*/
class XMLPrinter : public XMLVisitor
{
public:
	/** Construct the printer. If the FILE* is specified,
		this will print to the FILE. Else it will print
		to memory, and the result is available in CStr()
	*/
	XMLPrinter( FILE* file=0 );
	~XMLPrinter()	{}

	/** If streaming, write the BOM and declaration. */
	void PushHeader( bool writeBOM, bool writeDeclaration );
	/** If streaming, start writing an element.
	    The element must be closed with CloseElement()
	*/
	void OpenElement( const char* name );
	/// If streaming, add an attribute to an open element.
	void PushAttribute( const char* name, const char* value );
	void PushAttribute( const char* name, int value );
	void PushAttribute( const char* name, unsigned value );
	void PushAttribute( const char* name, bool value );
	void PushAttribute( const char* name, double value );
	/// If streaming, close the Element.
	void CloseElement();

	/// Add a text node.
	void PushText( const char* text, bool cdata=false );
	/// Add a comment
	void PushComment( const char* comment );

	void PushDeclaration( const char* value );
	void PushUnknown( const char* value );

	virtual bool VisitEnter( const XMLDocument& /*doc*/ );
	virtual bool VisitExit( const XMLDocument& /*doc*/ )			{ return true; }

	virtual bool VisitEnter( const XMLElement& element, const XMLAttribute* attribute );
	virtual bool VisitExit( const XMLElement& element );

	virtual bool Visit( const XMLText& text );
	virtual bool Visit( const XMLComment& comment );
	virtual bool Visit( const XMLDeclaration& declaration );
	virtual bool Visit( const XMLUnknown& unknown );

	/**
		If in print to memory mode, return a pointer to
		the XML file in memory.
	*/
	const char* CStr() const { return buffer.Mem(); }

private:
	void SealElement();
	void PrintSpace( int depth );
	void PrintString( const char*, bool restrictedEntitySet );	// prints out, after detecting entities.
	void Print( const char* format, ... );

	bool elementJustOpened;
	bool firstElement;
	FILE* fp;
	int depth;
	int textDepth;
	bool processEntities;

	enum {
		ENTITY_RANGE = 64,
		BUF_SIZE = 200
	};
	bool entityFlag[ENTITY_RANGE];
	bool restrictedEntityFlag[ENTITY_RANGE];

	DynArray< const char*, 10 > stack;
	DynArray< char, 20 > buffer, accumulator;
};


// tinyxml2.cpp

/*
Original code by Lee Thomason (www.grinninglizard.com)

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any
damages arising from the use of this software.

Permission is granted to anyone to use this software for any
purpose, including commercial applications, and to alter it and
redistribute it freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must
not claim that you wrote the original software. If you use this
software in a product, an acknowledgment in the product documentation
would be appreciated but is not required.

2. Altered source versions must be plainly marked as such, and
must not be misrepresented as being the original software.

3. This notice may not be removed or altered from any source
distribution.
*/

static const char LINE_FEED				= (char)0x0a;			// all line endings are normalized to LF
static const char LF = LINE_FEED;
static const char CARRIAGE_RETURN		= (char)0x0d;			// CR gets filtered out
static const char CR = CARRIAGE_RETURN;
static const char SINGLE_QUOTE			= '\'';
static const char DOUBLE_QUOTE			= '\"';

// Bunch of unicode info at:
//		http://www.unicode.org/faq/utf_bom.html
//	ef bb bf (Microsoft "lead bytes") - designates UTF-8

static const unsigned char TIXML_UTF_LEAD_0 = 0xefU;
static const unsigned char TIXML_UTF_LEAD_1 = 0xbbU;
static const unsigned char TIXML_UTF_LEAD_2 = 0xbfU;


#define DELETE_NODE( node )	{			\
	if ( node ) {						\
		MemPool* pool = node->memPool;	\
		node->~XMLNode();				\
		pool->Free( node );				\
	}									\
}
#define DELETE_ATTRIBUTE( attrib ) {		\
	if ( attrib ) {							\
		MemPool* pool = attrib->memPool;	\
		attrib->~XMLAttribute();			\
		pool->Free( attrib );				\
	}										\
}

struct Entity {
	const char* pattern;
	int length;
	char value;
};

static const int NUM_ENTITIES = 5;
static const Entity entities[NUM_ENTITIES] = 
{
	{ "quot", 4,	DOUBLE_QUOTE },
	{ "amp", 3,		'&'  },
	{ "apos", 4,	SINGLE_QUOTE },
	{ "lt",	2, 		'<'	 },
	{ "gt",	2,		'>'	 }
};


StrPair::~StrPair()
{
	Reset();
}


void StrPair::Reset()
{
	if ( flags & NEEDS_DELETE ) {
		delete [] start;
	}
	flags = 0;
	start = 0;
	end = 0;
}


void StrPair::SetStr( const char* str, int flags )
{
	Reset();
	size_t len = strlen( str );
	start = new char[ len+1 ];
	memcpy( start, str, len+1 );
	end = start + len;
	this->flags = flags | NEEDS_DELETE;
}


char* StrPair::ParseText( char* p, const char* endTag, int strFlags )
{
	TIXMLASSERT( endTag && *endTag );

	char* start = p;	// fixme: hides a member
	char  endChar = *endTag;
	int   length = (int)strlen( endTag );	

	// Inner loop of text parsing.
	while ( *p ) {
		if ( *p == endChar && strncmp( p, endTag, length ) == 0 ) {
			Set( start, p, strFlags );
			return p + length;
		}
		++p;
	}	
	return 0;
}


char* StrPair::ParseName( char* p )
{
	char* start = p;

	if ( !start || !(*start) ) {
		return 0;
	}

	if ( !XMLUtil::IsAlpha( *p ) ) {
		return 0;
	}

	while( *p && (
			   XMLUtil::IsAlphaNum( (unsigned char) *p ) 
			|| *p == '_'
			|| *p == '-'
			|| *p == '.'
			|| *p == ':' ))
	{
		++p;
	}

	if ( p > start ) {
		Set( start, p, 0 );
		return p;
	}
	return 0;
}



const char* StrPair::GetStr()
{
	if ( flags & NEEDS_FLUSH ) {
		*end = 0;
		flags ^= NEEDS_FLUSH;

		if ( flags ) {
			char* p = start;	// the read pointer
			char* q = start;	// the write pointer

			while( p < end ) {
				if ( (flags & NEEDS_NEWLINE_NORMALIZATION) && *p == CR ) {
					// CR-LF pair becomes LF
					// CR alone becomes LF
					// LF-CR becomes LF
					if ( *(p+1) == LF ) {
						p += 2;
					}
					else {
						++p;
					}
					*q++ = LF;
				}
				else if ( (flags & NEEDS_NEWLINE_NORMALIZATION) && *p == LF ) {
					if ( *(p+1) == CR ) {
						p += 2;
					}
					else {
						++p;
					}
					*q++ = LF;
				}
				else if ( (flags & NEEDS_ENTITY_PROCESSING) && *p == '&' ) {
					int i=0;

					// Entities handled by tinyXML2:
					// - special entities in the entity table [in/out]
					// - numeric character reference [in]
					//   &#20013; or &#x4e2d;

					if ( *(p+1) == '#' ) {
						char buf[10] = { 0 };
						int len;
						p = const_cast<char*>( XMLUtil::GetCharacterRef( p, buf, &len ) );
						for( int i=0; i<len; ++i ) {
							*q++ = buf[i];
						}
						TIXMLASSERT( q <= p );
					}
					else {
						for( i=0; i<NUM_ENTITIES; ++i ) {
							if (    strncmp( p+1, entities[i].pattern, entities[i].length ) == 0
								 && *(p+entities[i].length+1) == ';' ) 
							{
								// Found an entity convert;
								*q = entities[i].value;
								++q;
								p += entities[i].length + 2;
								break;
							}
						}
						if ( i == NUM_ENTITIES ) {
							// fixme: treat as error?
							++p;
							++q;
						}
					}
				}
				else {
					*q = *p;
					++p;
					++q;
				}
			}
			*q = 0;
		}
		flags = (flags & NEEDS_DELETE);
	}
	return start;
}




// --------- XMLUtil ----------- //

const char* XMLUtil::ReadBOM( const char* p, bool* bom )
{
	*bom = false;
	const unsigned char* pu = reinterpret_cast<const unsigned char*>(p);
	// Check for BOM:
	if (    *(pu+0) == TIXML_UTF_LEAD_0 
		 && *(pu+1) == TIXML_UTF_LEAD_1
		 && *(pu+2) == TIXML_UTF_LEAD_2 ) 
	{
		*bom = true;
		p += 3;
	}
	return p;
}


void XMLUtil::ConvertUTF32ToUTF8( unsigned long input, char* output, int* length )
{
	const unsigned long BYTE_MASK = 0xBF;
	const unsigned long BYTE_MARK = 0x80;
	const unsigned long FIRST_BYTE_MARK[7] = { 0x00, 0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC };

	if (input < 0x80) 
		*length = 1;
	else if ( input < 0x800 )
		*length = 2;
	else if ( input < 0x10000 )
		*length = 3;
	else if ( input < 0x200000 )
		*length = 4;
	else
		{ *length = 0; return; }	// This code won't covert this correctly anyway.

	output += *length;

	// Scary scary fall throughs.
	switch (*length) 
	{
		case 4:
			--output; 
			*output = (char)((input | BYTE_MARK) & BYTE_MASK); 
			input >>= 6;
		case 3:
			--output; 
			*output = (char)((input | BYTE_MARK) & BYTE_MASK); 
			input >>= 6;
		case 2:
			--output; 
			*output = (char)((input | BYTE_MARK) & BYTE_MASK); 
			input >>= 6;
		case 1:
			--output; 
			*output = (char)(input | FIRST_BYTE_MARK[*length]);
	}
}


const char* XMLUtil::GetCharacterRef( const char* p, char* value, int* length )
{
	// Presume an entity, and pull it out.
	*length = 0;

	if ( *(p+1) == '#' && *(p+2) )
	{
		unsigned long ucs = 0;
		int delta = 0;
		unsigned mult = 1;

		if ( *(p+2) == 'x' )
		{
			// Hexadecimal.
			if ( !*(p+3) ) return 0;

			const char* q = p+3;
			q = strchr( q, ';' );

			if ( !q || !*q ) return 0;

			delta = (int)(q-p);
			--q;

			while ( *q != 'x' )
			{
				if ( *q >= '0' && *q <= '9' )
					ucs += mult * (*q - '0');
				else if ( *q >= 'a' && *q <= 'f' )
					ucs += mult * (*q - 'a' + 10);
				else if ( *q >= 'A' && *q <= 'F' )
					ucs += mult * (*q - 'A' + 10 );
				else 
					return 0;
				mult *= 16;
				--q;
			}
		}
		else
		{
			// Decimal.
			if ( !*(p+2) ) return 0;

			const char* q = p+2;
			q = strchr( q, ';' );

			if ( !q || !*q ) return 0;

			delta = (int)(q-p);
			--q;

			while ( *q != '#' )
			{
				if ( *q >= '0' && *q <= '9' )
					ucs += mult * (*q - '0');
				else 
					return 0;
				mult *= 10;
				--q;
			}
		}
		// convert the UCS to UTF-8
		ConvertUTF32ToUTF8( ucs, value, length );
		return p + delta + 1;
	}
	return p+1;
}


char* XMLDocument::Identify( char* p, XMLNode** node ) 
{
	XMLNode* returnNode = 0;
	char* start = p;
	p = XMLUtil::SkipWhiteSpace( p );
	if( !p || !*p )
	{
		return p;
	}

	// What is this thing? 
	// - Elements start with a letter or underscore, but xml is reserved.
	// - Comments: <!--
	// - Decleration: <?
	// - Everthing else is unknown to tinyxml.
	//

	static const char* xmlHeader		= { "<?" };
	static const char* commentHeader	= { "<!--" };
	static const char* dtdHeader		= { "<!" };
	static const char* cdataHeader		= { "<![CDATA[" };
	static const char* elementHeader	= { "<" };	// and a header for everything else; check last.

	static const int xmlHeaderLen		= 2;
	static const int commentHeaderLen	= 4;
	static const int dtdHeaderLen		= 2;
	static const int cdataHeaderLen		= 9;
	static const int elementHeaderLen	= 1;

#if defined(_MSC_VER)
#pragma warning ( push )
#pragma warning ( disable : 4127 )
#endif
	TIXMLASSERT( sizeof( XMLComment ) == sizeof( XMLUnknown ) );		// use same memory pool
	TIXMLASSERT( sizeof( XMLComment ) == sizeof( XMLDeclaration ) );	// use same memory pool
#if defined(_MSC_VER)
#pragma warning (pop)
#endif
	if ( XMLUtil::StringEqual( p, xmlHeader, xmlHeaderLen ) ) {
		returnNode = new (commentPool.Alloc()) XMLDeclaration( this );
		returnNode->memPool = &commentPool;
		p += xmlHeaderLen;
	}
	else if ( XMLUtil::StringEqual( p, commentHeader, commentHeaderLen ) ) {
		returnNode = new (commentPool.Alloc()) XMLComment( this );
		returnNode->memPool = &commentPool;
		p += commentHeaderLen;
	}
	else if ( XMLUtil::StringEqual( p, cdataHeader, cdataHeaderLen ) ) {
		XMLText* text = new (textPool.Alloc()) XMLText( this );
		returnNode = text;
		returnNode->memPool = &textPool;
		p += cdataHeaderLen;
		text->SetCData( true );
	}
	else if ( XMLUtil::StringEqual( p, dtdHeader, dtdHeaderLen ) ) {
		returnNode = new (commentPool.Alloc()) XMLUnknown( this );
		returnNode->memPool = &commentPool;
		p += dtdHeaderLen;
	}
	else if ( XMLUtil::StringEqual( p, elementHeader, elementHeaderLen ) ) {
		returnNode = new (elementPool.Alloc()) XMLElement( this );
		returnNode->memPool = &elementPool;
		p += elementHeaderLen;
	}
	else {
		returnNode = new (textPool.Alloc()) XMLText( this );
		returnNode->memPool = &textPool;
		p = start;	// Back it up, all the text counts.
	}

	*node = returnNode;
	return p;
}


bool XMLDocument::Accept( XMLVisitor* visitor ) const
{
	if ( visitor->VisitEnter( *this ) )
	{
		for ( const XMLNode* node=FirstChild(); node; node=node->NextSibling() )
		{
			if ( !node->Accept( visitor ) )
				break;
		}
	}
	return visitor->VisitExit( *this );
}


// --------- XMLNode ----------- //

XMLNode::XMLNode( XMLDocument* doc ) :
	document( doc ),
	parent( 0 ),
	firstChild( 0 ), lastChild( 0 ),
	prev( 0 ), next( 0 )
{
}


XMLNode::~XMLNode()
{
	DeleteChildren();
	if ( parent ) {
		parent->Unlink( this );
	}
}


void XMLNode::SetValue( const char* str, bool staticMem )
{
	if ( staticMem )
		value.SetInternedStr( str );
	else
		value.SetStr( str );
}


void XMLNode::DeleteChildren()
{
	while( firstChild ) {
		XMLNode* node = firstChild;
		Unlink( node );
		
		DELETE_NODE( node );
	}
	firstChild = lastChild = 0;
}


void XMLNode::Unlink( XMLNode* child )
{
	TIXMLASSERT( child->parent == this );
	if ( child == firstChild ) 
		firstChild = firstChild->next;
	if ( child == lastChild ) 
		lastChild = lastChild->prev;

	if ( child->prev ) {
		child->prev->next = child->next;
	}
	if ( child->next ) {
		child->next->prev = child->prev;
	}
	child->parent = 0;
}


void XMLNode::DeleteChild( XMLNode* node )
{
	TIXMLASSERT( node->parent == this );
	DELETE_NODE( node );
}


XMLNode* XMLNode::InsertEndChild( XMLNode* addThis )
{
	if ( lastChild ) {
		TIXMLASSERT( firstChild );
		TIXMLASSERT( lastChild->next == 0 );
		lastChild->next = addThis;
		addThis->prev = lastChild;
		lastChild = addThis;

		addThis->next = 0;
	}
	else {
		TIXMLASSERT( firstChild == 0 );
		firstChild = lastChild = addThis;

		addThis->prev = 0;
		addThis->next = 0;
	}
	addThis->parent = this;
	return addThis;
}


XMLNode* XMLNode::InsertFirstChild( XMLNode* addThis )
{
	if ( firstChild ) {
		TIXMLASSERT( lastChild );
		TIXMLASSERT( firstChild->prev == 0 );

		firstChild->prev = addThis;
		addThis->next = firstChild;
		firstChild = addThis;

		addThis->prev = 0;
	}
	else {
		TIXMLASSERT( lastChild == 0 );
		firstChild = lastChild = addThis;

		addThis->prev = 0;
		addThis->next = 0;
	}
	addThis->parent = this;
	return addThis;
}


XMLNode* XMLNode::InsertAfterChild( XMLNode* afterThis, XMLNode* addThis )
{
	TIXMLASSERT( afterThis->parent == this );
	if ( afterThis->parent != this )
		return 0;

	if ( afterThis->next == 0 ) {
		// The last node or the only node.
		return InsertEndChild( addThis );
	}
	addThis->prev = afterThis;
	addThis->next = afterThis->next;
	afterThis->next->prev = addThis;
	afterThis->next = addThis;
	addThis->parent = this;
	return addThis;
}




const XMLElement* XMLNode::FirstChildElement( const char* value ) const
{
	for( XMLNode* node=firstChild; node; node=node->next ) {
		XMLElement* element = node->ToElement();
		if ( element ) {
			if ( !value || XMLUtil::StringEqual( element->Name(), value ) ) {
				return element;
			}
		}
	}
	return 0;
}


const XMLElement* XMLNode::LastChildElement( const char* value ) const
{
	for( XMLNode* node=lastChild; node; node=node->prev ) {
		XMLElement* element = node->ToElement();
		if ( element ) {
			if ( !value || XMLUtil::StringEqual( element->Name(), value ) ) {
				return element;
			}
		}
	}
	return 0;
}


const XMLElement* XMLNode::NextSiblingElement( const char* value ) const
{
	for( XMLNode* element=this->next; element; element = element->next ) {
		if (    element->ToElement() 
			 && (!value || XMLUtil::StringEqual( value, element->Value() ))) 
		{
			return element->ToElement();
		}
	}
	return 0;
}


const XMLElement* XMLNode::PreviousSiblingElement( const char* value ) const
{
	for( XMLNode* element=this->prev; element; element = element->prev ) {
		if (    element->ToElement()
			 && (!value || XMLUtil::StringEqual( value, element->Value() ))) 
		{
			return element->ToElement();
		}
	}
	return 0;
}


char* XMLNode::ParseDeep( char* p, StrPair* parentEnd )
{
	// This is a recursive method, but thinking about it "at the current level"
	// it is a pretty simple flat list:
	//		<foo/>
	//		<!-- comment -->
	//
	// With a special case:
	//		<foo>
	//		</foo>
	//		<!-- comment -->
	//		
	// Where the closing element (/foo) *must* be the next thing after the opening
	// element, and the names must match. BUT the tricky bit is that the closing
	// element will be read by the child.
	// 
	// 'endTag' is the end tag for this node, it is returned by a call to a child.
	// 'parentEnd' is the end tag for the parent, which is filled in and returned.

	while( p && *p ) {
		XMLNode* node = 0;

		p = document->Identify( p, &node );
		if ( p == 0 || node == 0 ) {
			break;
		}

		StrPair endTag;
		p = node->ParseDeep( p, &endTag );
		if ( !p ) {
			DELETE_NODE( node );
			node = 0;
			if ( !document->Error() ) {
				document->SetError( XML_ERROR_PARSING, 0, 0 );
			}
			break;
		}

		// We read the end tag. Return it to the parent.
		if ( node->ToElement() && node->ToElement()->ClosingType() == XMLElement::CLOSING ) {
			if ( parentEnd ) {
				*parentEnd = ((XMLElement*)node)->value;
			}
			DELETE_NODE( node );
			return p;
		}

		// Handle an end tag returned to this level.
		// And handle a bunch of annoying errors.
		XMLElement* ele = node->ToElement();
		if ( ele ) {
			if ( endTag.Empty() && ele->ClosingType() == XMLElement::OPEN ) {
				document->SetError( XML_ERROR_MISMATCHED_ELEMENT, node->Value(), 0 );
				p = 0;
			}
			else if ( !endTag.Empty() && ele->ClosingType() != XMLElement::OPEN ) {
				document->SetError( XML_ERROR_MISMATCHED_ELEMENT, node->Value(), 0 );
				p = 0;
			}
			else if ( !endTag.Empty() ) {
				if ( !XMLUtil::StringEqual( endTag.GetStr(), node->Value() )) { 
					document->SetError( XML_ERROR_MISMATCHED_ELEMENT, node->Value(), 0 );
					p = 0;
				}
			}
		}
		if ( p == 0 ) {
			DELETE_NODE( node );
			node = 0;
		}
		if ( node ) {
			this->InsertEndChild( node );
		}
	}
	return 0;
}

// --------- XMLText ---------- //
char* XMLText::ParseDeep( char* p, StrPair* )
{
	const char* start = p;
	if ( this->CData() ) {
		p = value.ParseText( p, "]]>", StrPair::NEEDS_NEWLINE_NORMALIZATION );
		if ( !p ) {
			document->SetError( XML_ERROR_PARSING_CDATA, start, 0 );
		}
		return p;
	}
	else {
		p = value.ParseText( p, "<", document->ProcessEntities() ? StrPair::TEXT_ELEMENT : StrPair::TEXT_ELEMENT_LEAVE_ENTITIES );
		if ( !p ) {
			document->SetError( XML_ERROR_PARSING_TEXT, start, 0 );
		}
		if ( p && *p ) {
			return p-1;
		}
	}
	return 0;
}


XMLNode* XMLText::ShallowClone( XMLDocument* doc ) const
{
	if ( !doc ) {
		doc = document;
	}
	XMLText* text = doc->NewText( Value() );	// fixme: this will always allocate memory. Intern?
	text->SetCData( this->CData() );
	return text;
}


bool XMLText::ShallowEqual( const XMLNode* compare ) const
{
	return ( compare->ToText() && XMLUtil::StringEqual( compare->ToText()->Value(), Value() ));
}


bool XMLText::Accept( XMLVisitor* visitor ) const
{
	return visitor->Visit( *this );
}


// --------- XMLComment ---------- //

XMLComment::XMLComment( XMLDocument* doc ) : XMLNode( doc )
{
}


XMLComment::~XMLComment()
{
	//printf( "~XMLComment\n" );
}


char* XMLComment::ParseDeep( char* p, StrPair* )
{
	// Comment parses as text.
	const char* start = p;
	p = value.ParseText( p, "-->", StrPair::COMMENT );
	if ( p == 0 ) {
		document->SetError( XML_ERROR_PARSING_COMMENT, start, 0 );
	}
	return p;
}


XMLNode* XMLComment::ShallowClone( XMLDocument* doc ) const
{
	if ( !doc ) {
		doc = document;
	}
	XMLComment* comment = doc->NewComment( Value() );	// fixme: this will always allocate memory. Intern?
	return comment;
}


bool XMLComment::ShallowEqual( const XMLNode* compare ) const
{
	return ( compare->ToComment() && XMLUtil::StringEqual( compare->ToComment()->Value(), Value() ));
}


bool XMLComment::Accept( XMLVisitor* visitor ) const
{
	return visitor->Visit( *this );
}


// --------- XMLDeclaration ---------- //

XMLDeclaration::XMLDeclaration( XMLDocument* doc ) : XMLNode( doc )
{
}


XMLDeclaration::~XMLDeclaration()
{
	//printf( "~XMLDeclaration\n" );
}


char* XMLDeclaration::ParseDeep( char* p, StrPair* )
{
	// Declaration parses as text.
	const char* start = p;
	p = value.ParseText( p, "?>", StrPair::NEEDS_NEWLINE_NORMALIZATION );
	if ( p == 0 ) {
		document->SetError( XML_ERROR_PARSING_DECLARATION, start, 0 );
	}
	return p;
}


XMLNode* XMLDeclaration::ShallowClone( XMLDocument* doc ) const
{
	if ( !doc ) {
		doc = document;
	}
	XMLDeclaration* dec = doc->NewDeclaration( Value() );	// fixme: this will always allocate memory. Intern?
	return dec;
}


bool XMLDeclaration::ShallowEqual( const XMLNode* compare ) const
{
	return ( compare->ToDeclaration() && XMLUtil::StringEqual( compare->ToDeclaration()->Value(), Value() ));
}



bool XMLDeclaration::Accept( XMLVisitor* visitor ) const
{
	return visitor->Visit( *this );
}

// --------- XMLUnknown ---------- //

XMLUnknown::XMLUnknown( XMLDocument* doc ) : XMLNode( doc )
{
}


XMLUnknown::~XMLUnknown()
{
}


char* XMLUnknown::ParseDeep( char* p, StrPair* )
{
	// Unknown parses as text.
	const char* start = p;

	p = value.ParseText( p, ">", StrPair::NEEDS_NEWLINE_NORMALIZATION );
	if ( !p ) {
		document->SetError( XML_ERROR_PARSING_UNKNOWN, start, 0 );
	}
	return p;
}


XMLNode* XMLUnknown::ShallowClone( XMLDocument* doc ) const
{
	if ( !doc ) {
		doc = document;
	}
	XMLUnknown* text = doc->NewUnknown( Value() );	// fixme: this will always allocate memory. Intern?
	return text;
}


bool XMLUnknown::ShallowEqual( const XMLNode* compare ) const
{
	return ( compare->ToUnknown() && XMLUtil::StringEqual( compare->ToUnknown()->Value(), Value() ));
}


bool XMLUnknown::Accept( XMLVisitor* visitor ) const
{
	return visitor->Visit( *this );
}

// --------- XMLAttribute ---------- //
char* XMLAttribute::ParseDeep( char* p, bool processEntities )
{
	p = name.ParseText( p, "=", StrPair::ATTRIBUTE_NAME );
	if ( !p || !*p ) return 0;

	char endTag[2] = { *p, 0 };
	++p;
	p = value.ParseText( p, endTag, processEntities ? StrPair::ATTRIBUTE_VALUE : StrPair::ATTRIBUTE_VALUE_LEAVE_ENTITIES );
	//if ( value.Empty() ) return 0;
	return p;
}


void XMLAttribute::SetName( const char* n )
{
	name.SetStr( n );
}


int XMLAttribute::QueryIntValue( int* value ) const
{
	if ( TIXML_SSCANF( Value(), "%d", value ) == 1 )
		return XML_NO_ERROR;
	return XML_WRONG_ATTRIBUTE_TYPE;
}


int XMLAttribute::QueryUnsignedValue( unsigned int* value ) const
{
	if ( TIXML_SSCANF( Value(), "%u", value ) == 1 )
		return XML_NO_ERROR;
	return XML_WRONG_ATTRIBUTE_TYPE;
}


int XMLAttribute::QueryBoolValue( bool* value ) const
{
	int ival = -1;
	QueryIntValue( &ival );

	if ( ival > 0 || XMLUtil::StringEqual( Value(), "true" ) ) {
		*value = true;
		return XML_NO_ERROR;
	}
	else if ( ival == 0 || XMLUtil::StringEqual( Value(), "false" ) ) {
		*value = false;
		return XML_NO_ERROR;
	}
	return XML_WRONG_ATTRIBUTE_TYPE;
}


int XMLAttribute::QueryDoubleValue( double* value ) const
{
	if ( TIXML_SSCANF( Value(), "%lf", value ) == 1 )
		return XML_NO_ERROR;
	return XML_WRONG_ATTRIBUTE_TYPE;
}


int XMLAttribute::QueryFloatValue( float* value ) const
{
	if ( TIXML_SSCANF( Value(), "%f", value ) == 1 )
		return XML_NO_ERROR;
	return XML_WRONG_ATTRIBUTE_TYPE;
}


void XMLAttribute::SetAttribute( const char* v )
{
	value.SetStr( v );
}


void XMLAttribute::SetAttribute( int v )
{
	char buf[BUF_SIZE];
	TIXML_SNPRINTF( buf, BUF_SIZE, "%d", v );	
	value.SetStr( buf );
}


void XMLAttribute::SetAttribute( unsigned v )
{
	char buf[BUF_SIZE];
	TIXML_SNPRINTF( buf, BUF_SIZE, "%u", v );	
	value.SetStr( buf );
}


void XMLAttribute::SetAttribute( bool v )
{
	char buf[BUF_SIZE];
	TIXML_SNPRINTF( buf, BUF_SIZE, "%d", v ? 1 : 0 );	
	value.SetStr( buf );
}

void XMLAttribute::SetAttribute( double v )
{
	char buf[BUF_SIZE];
	TIXML_SNPRINTF( buf, BUF_SIZE, "%f", v );	
	value.SetStr( buf );
}

void XMLAttribute::SetAttribute( float v )
{
	char buf[BUF_SIZE];
	TIXML_SNPRINTF( buf, BUF_SIZE, "%f", v );	
	value.SetStr( buf );
}


// --------- XMLElement ---------- //
XMLElement::XMLElement( XMLDocument* doc ) : XMLNode( doc ),
	closingType( 0 ),
	rootAttribute( 0 )
{
}


XMLElement::~XMLElement()
{
	while( rootAttribute ) {
		XMLAttribute* next = rootAttribute->next;
		DELETE_ATTRIBUTE( rootAttribute );
		rootAttribute = next;
	}
}


XMLAttribute* XMLElement::FindAttribute( const char* name )
{
	XMLAttribute* a = 0;
	for( a=rootAttribute; a; a = a->next ) {
		if ( XMLUtil::StringEqual( a->Name(), name ) )
			return a;
	}
	return 0;
}


const XMLAttribute* XMLElement::FindAttribute( const char* name ) const
{
	XMLAttribute* a = 0;
	for( a=rootAttribute; a; a = a->next ) {
		if ( XMLUtil::StringEqual( a->Name(), name ) )
			return a;
	}
	return 0;
}


const char* XMLElement::Attribute( const char* name, const char* value ) const
{ 
	const XMLAttribute* a = FindAttribute( name ); 
	if ( !a ) 
		return 0; 
	if ( !value || XMLUtil::StringEqual( a->Value(), value ))
		return a->Value();
	return 0;
}


const char* XMLElement::GetText() const
{
	if ( FirstChild() && FirstChild()->ToText() ) {
		return FirstChild()->ToText()->Value();
	}
	return 0;
}


XMLAttribute* XMLElement::FindOrCreateAttribute( const char* name )
{
	XMLAttribute* last = 0;
	XMLAttribute* attrib = 0;
	for( attrib = rootAttribute;
		 attrib;
		 last = attrib, attrib = attrib->next )
	{		 
		if ( XMLUtil::StringEqual( attrib->Name(), name ) ) {
			break;
		}
	}
	if ( !attrib ) {
		attrib = new (document->attributePool.Alloc() ) XMLAttribute();
		attrib->memPool = &document->attributePool;
		if ( last ) {
			last->next = attrib;
		}
		else {
			rootAttribute = attrib;
		}
		attrib->SetName( name );
	}
	return attrib;
}


void XMLElement::DeleteAttribute( const char* name )
{
	XMLAttribute* prev = 0;
	for( XMLAttribute* a=rootAttribute; a; a=a->next ) {
		if ( XMLUtil::StringEqual( name, a->Name() ) ) {
			if ( prev ) {
				prev->next = a->next;
			}
			else {
				rootAttribute = a->next;
			}
			DELETE_ATTRIBUTE( a );
			break;
		}
		prev = a;
	}
}


char* XMLElement::ParseAttributes( char* p )
{
	const char* start = p;
	XMLAttribute* prevAttribute = 0;

	// Read the attributes.
	while( p ) {
		p = XMLUtil::SkipWhiteSpace( p );
		if ( !p || !(*p) ) {
			document->SetError( XML_ERROR_PARSING_ELEMENT, start, Name() );
			return 0;
		}

		// attribute.
		if ( XMLUtil::IsAlpha( *p ) ) {
			XMLAttribute* attrib = new (document->attributePool.Alloc() ) XMLAttribute();
			attrib->memPool = &document->attributePool;

			p = attrib->ParseDeep( p, document->ProcessEntities() );
			if ( !p || Attribute( attrib->Name() ) ) {
				DELETE_ATTRIBUTE( attrib );
				document->SetError( XML_ERROR_PARSING_ATTRIBUTE, start, p );
				return 0;
			}
			// There is a minor bug here: if the attribute in the source xml
			// document is duplicated, it will not be detected and the
			// attribute will be doubly added. However, tracking the 'prevAttribute'
			// avoids re-scanning the attribute list. Preferring performance for
			// now, may reconsider in the future.
			if ( prevAttribute ) { 
				prevAttribute->next = attrib;
			}
			else {
				rootAttribute = attrib;
			}	
			prevAttribute = attrib;
		}
		// end of the tag
		else if ( *p == '/' && *(p+1) == '>' ) {
			closingType = CLOSED;
			return p+2;	// done; sealed element.
		}
		// end of the tag
		else if ( *p == '>' ) {
			++p;
			break;
		}
		else {
			document->SetError( XML_ERROR_PARSING_ELEMENT, start, p );
			return 0;
		}
	}
	return p;
}


//
//	<ele></ele>
//	<ele>foo<b>bar</b></ele>
//
char* XMLElement::ParseDeep( char* p, StrPair* strPair )
{
	// Read the element name.
	p = XMLUtil::SkipWhiteSpace( p );
	if ( !p ) return 0;

	// The closing element is the </element> form. It is
	// parsed just like a regular element then deleted from
	// the DOM.
	if ( *p == '/' ) {
		closingType = CLOSING;
		++p;
	}

	p = value.ParseName( p );
	if ( value.Empty() ) return 0;

	p = ParseAttributes( p );
	if ( !p || !*p || closingType ) 
		return p;

	p = XMLNode::ParseDeep( p, strPair );
	return p;
}



XMLNode* XMLElement::ShallowClone( XMLDocument* doc ) const
{
	if ( !doc ) {
		doc = document;
	}
	XMLElement* element = doc->NewElement( Value() );					// fixme: this will always allocate memory. Intern?
	for( const XMLAttribute* a=FirstAttribute(); a; a=a->Next() ) {
		element->SetAttribute( a->Name(), a->Value() );					// fixme: this will always allocate memory. Intern?
	}
	return element;
}


bool XMLElement::ShallowEqual( const XMLNode* compare ) const
{
	const XMLElement* other = compare->ToElement();
	if ( other && XMLUtil::StringEqual( other->Value(), Value() )) {

		const XMLAttribute* a=FirstAttribute();
		const XMLAttribute* b=other->FirstAttribute();

		while ( a && b ) {
			if ( !XMLUtil::StringEqual( a->Value(), b->Value() ) ) {
				return false;
			}
		}	
		if ( a || b ) {
			// different count
			return false;
		}
		return true;
	}
	return false;
}


bool XMLElement::Accept( XMLVisitor* visitor ) const
{
	if ( visitor->VisitEnter( *this, rootAttribute ) ) 
	{
		for ( const XMLNode* node=FirstChild(); node; node=node->NextSibling() )
		{
			if ( !node->Accept( visitor ) )
				break;
		}
	}
	return visitor->VisitExit( *this );
}


// --------- XMLDocument ----------- //
XMLDocument::XMLDocument( bool _processEntities ) :
	XMLNode( 0 ),
	writeBOM( false ),
	processEntities( _processEntities ),
	errorID( 0 ),
	errorStr1( 0 ),
	errorStr2( 0 ),
	charBuffer( 0 )
{
	document = this;	// avoid warning about 'this' in initializer list
}


XMLDocument::~XMLDocument()
{
	DeleteChildren();
	delete [] charBuffer;

#if 0
	textPool.Trace( "text" );
	elementPool.Trace( "element" );
	commentPool.Trace( "comment" );
	attributePool.Trace( "attribute" );
#endif

	TIXMLASSERT( textPool.CurrentAllocs() == 0 );
	TIXMLASSERT( elementPool.CurrentAllocs() == 0 );
	TIXMLASSERT( commentPool.CurrentAllocs() == 0 );
	TIXMLASSERT( attributePool.CurrentAllocs() == 0 );
}


void XMLDocument::InitDocument()
{
	errorID = XML_NO_ERROR;
	errorStr1 = 0;
	errorStr2 = 0;

	delete [] charBuffer;
	charBuffer = 0;

}


XMLElement* XMLDocument::NewElement( const char* name )
{
	XMLElement* ele = new (elementPool.Alloc()) XMLElement( this );
	ele->memPool = &elementPool;
	ele->SetName( name );
	return ele;
}


XMLComment* XMLDocument::NewComment( const char* str )
{
	XMLComment* comment = new (commentPool.Alloc()) XMLComment( this );
	comment->memPool = &commentPool;
	comment->SetValue( str );
	return comment;
}


XMLText* XMLDocument::NewText( const char* str )
{
	XMLText* text = new (textPool.Alloc()) XMLText( this );
	text->memPool = &textPool;
	text->SetValue( str );
	return text;
}


XMLDeclaration* XMLDocument::NewDeclaration( const char* str )
{
	XMLDeclaration* dec = new (commentPool.Alloc()) XMLDeclaration( this );
	dec->memPool = &commentPool;
	dec->SetValue( str );
	return dec;
}


XMLUnknown* XMLDocument::NewUnknown( const char* str )
{
	XMLUnknown* unk = new (commentPool.Alloc()) XMLUnknown( this );
	unk->memPool = &commentPool;
	unk->SetValue( str );
	return unk;
}


int XMLDocument::LoadFile( const char* filename )
{
	DeleteChildren();
	InitDocument();

#if defined(_MSC_VER)
#pragma warning ( push )
#pragma warning ( disable : 4996 )		// Fail to see a compelling reason why this should be deprecated.
#endif
	FILE* fp = fopen( filename, "rb" );
#if defined(_MSC_VER)
#pragma warning ( pop )
#endif
	if ( !fp ) {
		SetError( XML_ERROR_FILE_NOT_FOUND, filename, 0 );
		return errorID;
	}
	LoadFile( fp );
	fclose( fp );
	return errorID;
}


int XMLDocument::LoadFile( FILE* fp ) 
{
	DeleteChildren();
	InitDocument();

	fseek( fp, 0, SEEK_END );
	unsigned size = ftell( fp );
	fseek( fp, 0, SEEK_SET );

	if ( size == 0 ) {
		return errorID;
	}

	charBuffer = new char[size+1];
	fread( charBuffer, size, 1, fp );
	charBuffer[size] = 0;

	const char* p = charBuffer;
	p = XMLUtil::SkipWhiteSpace( p );
	p = XMLUtil::ReadBOM( p, &writeBOM );
	if ( !p || !*p ) {
		SetError( XML_ERROR_EMPTY_DOCUMENT, 0, 0 );
		return errorID;
	}

	ParseDeep( charBuffer + (p-charBuffer), 0 );
	return errorID;
}


int XMLDocument::SaveFile( const char* filename )
{
#if defined(_MSC_VER)
#pragma warning ( push )
#pragma warning ( disable : 4996 )		// Fail to see a compelling reason why this should be deprecated.
#endif
	FILE* fp = fopen( filename, "w" );
#if defined(_MSC_VER)
#pragma warning ( pop )
#endif
	if ( !fp ) {
		SetError( XML_ERROR_FILE_COULD_NOT_BE_OPENED, filename, 0 );
		return errorID;
	}
	SaveFile(fp);
	fclose( fp );
	return errorID;
}


int XMLDocument::SaveFile( FILE* fp )
{
	XMLPrinter stream( fp );
	Print( &stream );
	return errorID;
}


int XMLDocument::Parse( const char* p )
{
	DeleteChildren();
	InitDocument();

	if ( !p || !*p ) {
		SetError( XML_ERROR_EMPTY_DOCUMENT, 0, 0 );
		return errorID;
	}
	p = XMLUtil::SkipWhiteSpace( p );
	p = XMLUtil::ReadBOM( p, &writeBOM );
	if ( !p || !*p ) {
		SetError( XML_ERROR_EMPTY_DOCUMENT, 0, 0 );
		return errorID;
	}

	size_t len = strlen( p );
	charBuffer = new char[ len+1 ];
	memcpy( charBuffer, p, len+1 );

	
	ParseDeep( charBuffer, 0 );
	return errorID;
}


void XMLDocument::Print( XMLPrinter* streamer ) 
{
	XMLPrinter stdStreamer( stdout );
	if ( !streamer )
		streamer = &stdStreamer;
	Accept( streamer );
}


void XMLDocument::SetError( int error, const char* str1, const char* str2 )
{
	errorID = error;
	errorStr1 = str1;
	errorStr2 = str2;
}


void XMLDocument::PrintError() const 
{
	if ( errorID ) {
		static const int LEN = 20;
		char buf1[LEN] = { 0 };
		char buf2[LEN] = { 0 };
		
		if ( errorStr1 ) {
			TIXML_SNPRINTF( buf1, LEN, "%s", errorStr1 );
		}
		if ( errorStr2 ) {
			TIXML_SNPRINTF( buf2, LEN, "%s", errorStr2 );
		}

		printf( "XMLDocument error id=%d str1=%s str2=%s\n",
			    errorID, buf1, buf2 );
	}
}


XMLPrinter::XMLPrinter( FILE* file ) : 
	elementJustOpened( false ), 
	firstElement( true ),
	fp( file ), 
	depth( 0 ), 
	textDepth( -1 ),
	processEntities( true )
{
	for( int i=0; i<ENTITY_RANGE; ++i ) {
		entityFlag[i] = false;
		restrictedEntityFlag[i] = false;
	}
	for( int i=0; i<NUM_ENTITIES; ++i ) {
		TIXMLASSERT( entities[i].value < ENTITY_RANGE );
		if ( entities[i].value < ENTITY_RANGE ) {
			entityFlag[ (int)entities[i].value ] = true;
		}
	}
	restrictedEntityFlag[(int)'&'] = true;
	restrictedEntityFlag[(int)'<'] = true;
	restrictedEntityFlag[(int)'>'] = true;	// not required, but consistency is nice
	buffer.Push( 0 );
}


void XMLPrinter::Print( const char* format, ... )
{
    va_list     va;
    va_start( va, format );

	if ( fp ) {
		vfprintf( fp, format, va );
	}
	else {
		// This seems brutally complex. Haven't figured out a better
		// way on windows.
		#ifdef _MSC_VER
			int len = -1;
			int expand = 1000;
			while ( len < 0 ) {
				len = vsnprintf_s( accumulator.Mem(), accumulator.Capacity(), _TRUNCATE, format, va );
				if ( len < 0 ) {
					expand *= 3/2;
					accumulator.PushArr( expand );
				}
			}
			char* p = buffer.PushArr( len ) - 1;
			memcpy( p, accumulator.Mem(), len+1 );
		#else
			int len = vsnprintf( 0, 0, format, va );
			// Close out and re-start the va-args
			va_end( va );
			va_start( va, format );		
			char* p = buffer.PushArr( len ) - 1;
			vsnprintf( p, len+1, format, va );
		#endif
	}
    va_end( va );
}


void XMLPrinter::PrintSpace( int depth )
{
	for( int i=0; i<depth; ++i ) {
		Print( "    " );
	}
}


void XMLPrinter::PrintString( const char* p, bool restricted )
{
	// Look for runs of bytes between entities to print.
	const char* q = p;
	const bool* flag = restricted ? restrictedEntityFlag : entityFlag;

	if ( processEntities ) {
		while ( *q ) {
			// Remember, char is sometimes signed. (How many times has that bitten me?)
			if ( *q > 0 && *q < ENTITY_RANGE ) {
				// Check for entities. If one is found, flush
				// the stream up until the entity, write the 
				// entity, and keep looking.
				if ( flag[(unsigned)(*q)] ) {
					while ( p < q ) {
						Print( "%c", *p );
						++p;
					}
					for( int i=0; i<NUM_ENTITIES; ++i ) {
						if ( entities[i].value == *q ) {
							Print( "&%s;", entities[i].pattern );
							break;
						}
					}
					++p;
				}
			}
			++q;
		}
	}
	// Flush the remaining string. This will be the entire
	// string if an entity wasn't found.
	if ( !processEntities || (q-p > 0) ) {
		Print( "%s", p );
	}
}


void XMLPrinter::PushHeader( bool writeBOM, bool writeDec )
{
	static const unsigned char bom[] = { TIXML_UTF_LEAD_0, TIXML_UTF_LEAD_1, TIXML_UTF_LEAD_2, 0 };
	if ( writeBOM ) {
		Print( "%s", bom );
	}
	if ( writeDec ) {
		PushDeclaration( "xml version=\"1.0\"" );
	}
}


void XMLPrinter::OpenElement( const char* name )
{
	if ( elementJustOpened ) {
		SealElement();
	}
	stack.Push( name );

	if ( textDepth < 0 && !firstElement ) {
		Print( "\n" );
		PrintSpace( depth );
	}

	Print( "<%s", name );
	elementJustOpened = true;
	firstElement = false;
	++depth;
}


void XMLPrinter::PushAttribute( const char* name, const char* value )
{
	TIXMLASSERT( elementJustOpened );
	Print( " %s=\"", name );
	PrintString( value, false );
	Print( "\"" );
}


void XMLPrinter::PushAttribute( const char* name, int v )
{
	char buf[BUF_SIZE];
	TIXML_SNPRINTF( buf, BUF_SIZE, "%d", v );	
	PushAttribute( name, buf );
}


void XMLPrinter::PushAttribute( const char* name, unsigned v )
{
	char buf[BUF_SIZE];
	TIXML_SNPRINTF( buf, BUF_SIZE, "%u", v );	
	PushAttribute( name, buf );
}


void XMLPrinter::PushAttribute( const char* name, bool v )
{
	char buf[BUF_SIZE];
	TIXML_SNPRINTF( buf, BUF_SIZE, "%d", v ? 1 : 0 );	
	PushAttribute( name, buf );
}


void XMLPrinter::PushAttribute( const char* name, double v )
{
	char buf[BUF_SIZE];
	TIXML_SNPRINTF( buf, BUF_SIZE, "%f", v );	
	PushAttribute( name, buf );
}


void XMLPrinter::CloseElement()
{
	--depth;
	const char* name = stack.Pop();

	if ( elementJustOpened ) {
		Print( "/>" );
	}
	else {
		if ( textDepth < 0 ) {
			Print( "\n" );
			PrintSpace( depth );
		}
		Print( "</%s>", name );
	}

	if ( textDepth == depth )
		textDepth = -1;
	if ( depth == 0 )
		Print( "\n" );
	elementJustOpened = false;
}


void XMLPrinter::SealElement()
{
	elementJustOpened = false;
	Print( ">" );
}


void XMLPrinter::PushText( const char* text, bool cdata )
{
	textDepth = depth-1;

	if ( elementJustOpened ) {
		SealElement();
	}
	if ( cdata ) {
		Print( "<![CDATA[" );
		Print( "%s", text );
		Print( "]]>" );
	}
	else {
		PrintString( text, true );
	}
}


void XMLPrinter::PushComment( const char* comment )
{
	if ( elementJustOpened ) {
		SealElement();
	}
	if ( textDepth < 0 && !firstElement ) {
		Print( "\n" );
		PrintSpace( depth );
	}
	firstElement = false;
	Print( "<!--%s-->", comment );
}


void XMLPrinter::PushDeclaration( const char* value )
{
	if ( elementJustOpened ) {
		SealElement();
	}
	if ( textDepth < 0 && !firstElement) {
		Print( "\n" );
		PrintSpace( depth );
	}
	firstElement = false;
	Print( "<?%s?>", value );
}


void XMLPrinter::PushUnknown( const char* value )
{
	if ( elementJustOpened ) {
		SealElement();
	}
	if ( textDepth < 0 && !firstElement ) {
		Print( "\n" );
		PrintSpace( depth );
	}
	firstElement = false;
	Print( "<!%s>", value );
}


bool XMLPrinter::VisitEnter( const XMLDocument& doc )
{
	processEntities = doc.ProcessEntities();
	if ( doc.HasBOM() ) {
		PushHeader( true, false );
	}
	return true;
}


bool XMLPrinter::VisitEnter( const XMLElement& element, const XMLAttribute* attribute )
{
	OpenElement( element.Name() );
	while ( attribute ) {
		PushAttribute( attribute->Name(), attribute->Value() );
		attribute = attribute->Next();
	}
	return true;
}


bool XMLPrinter::VisitExit( const XMLElement& )
{
	CloseElement();
	return true;
}


bool XMLPrinter::Visit( const XMLText& text )
{
	PushText( text.Value(), text.CData() );
	return true;
}


bool XMLPrinter::Visit( const XMLComment& comment )
{
	PushComment( comment.Value() );
	return true;
}

bool XMLPrinter::Visit( const XMLDeclaration& declaration )
{
	PushDeclaration( declaration.Value() );
	return true;
}


bool XMLPrinter::Visit( const XMLUnknown& unknown )
{
	PushUnknown( unknown.Value() );
	return true;
}

}	// tinyxml2


#endif // TINYXML2_INCLUDED
