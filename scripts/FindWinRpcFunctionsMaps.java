// Description:
// This script parses all Windows RPC servers from imported modules in a Ghidra project.
// Next, it retrieves all the RPC functions from each RPC Server and every function it calls (i.e Win32 API functions)
// Then, it crafts a JSON string object (manually) for each function which is later added to an array.
// Finally, it takes the array of functions in JSON strings format and appends it to a JSON file on disk.
//
// References:
// Code (Java) to find initial RPC functions is from Sektor7 (reenz0h):
//   https://blog.sektor7.net/#!res/2019/RPC-parser.md
//   https://blog.sektor7.net/res/2019/RPCparser.java
// Initial Code (Python) to find additional functions being called is from Adam Chesters (_xpn_) research:
//   https://blog.xpnsec.com/analysing-rpc-with-ghidra-neo4j/
//   https://github.com/xpn/RpcEnum/blob/master/post_script.py
//
//@author Sektor7 Labs (reenz0h), Adam Chester (_xpn_) (Python Code Reference), Roberto Rodriguez (Cyb3rWard0g) (Extended Code)
//@category Functions
//@keybinding 
//@menupath 
//@toolbar

import ghidra.app.script.GhidraScript;
import ghidra.program.model.util.*;
import ghidra.program.model.reloc.*;
import ghidra.program.model.data.*;
import ghidra.program.model.block.*;
import ghidra.program.model.symbol.*;
import ghidra.program.model.scalar.*;
import ghidra.program.model.mem.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.lang.*;
import ghidra.program.model.pcode.*;
import ghidra.program.model.address.*;
import java.util.Set;
import java.util.Arrays;
import java.util.ArrayList;
import java.io.FileWriter;
import java.io.File;
import java.io.BufferedWriter;
import java.io.IOException;

public class FindWinRpcFunctionsMaps extends GhidraScript {

	// Set allFunctions variable to store all functions found
	private ArrayList<String> allFunctions;

	int MAX_DEPTH = 5;
	// Code adapted from Adam Chester's Python script to recursively look for Called Functions
	// https://github.com/xpn/RpcEnum/blob/master/post_script.py#L33-L55
	public void GetCalled(Function f, int depth) {
		if (depth > MAX_DEPTH || f == null) {
			return;
		}
		println("  [+] Getting Functions called by " + f.getName());
		// Get set of functions that the initial function calls
    	Set<Function> called = f.getCalledFunctions(getMonitor());
		if (called.size() > 0) {
			for (Function c:called ) {
				println("    [>] Processing Called Function " + c.getName());
				if (c.isExternal()) {
					String strtmp="";
					strtmp+="{\"Module\":\"" + c.getExternalLocation().getLibraryName().toString().replace("\\","/") + "\",";
					strtmp+="\"FunctionName\":\"" + c.getName() + "\",";
					strtmp+="\"FunctionType\":\"ExtFunction\",";
					strtmp+="\"CalledByModule\":\"" + f.getProgram().getExecutablePath().toString().replace("\\","/") + "\",";
					strtmp+="\"CalledBy\":\"" + f.getName() + "\",";
					strtmp+="\"Address\":\"0\"}";
					allFunctions.add(strtmp);
				}
				else {
					String strtmp="";
					strtmp+="{\"Module\":\"" + c.getProgram().getExecutablePath().toString().replace("\\","/") + "\",";
					strtmp+="\"FunctionName\":\"" + c.getName() + "\",";
					strtmp+="\"FunctionType\":\"IntFunction\",";
					strtmp+="\"CalledByModule\":\"" + f.getProgram().getExecutablePath().toString().replace("\\","/") + "\",";
					strtmp+="\"CalledBy\":\"" + f.getName() + "\",";
					strtmp+="\"Address\":\"" + c.getEntryPoint().toString() + "\"}";
					allFunctions.add(strtmp);
				}
				// Parse further functions
            	GetCalled(c, depth+1);
			}
		}
	}

	// helper methods
	public long bytesToLong(byte[] bytes) {
		long value = 0;
		for (int i = 0; i < bytes.length; i++) {
		   value += ((long) bytes[i] & 0xffL) << (8 * i);
		}
		return value;
	}

	public int bytesToInt(byte[] bytes) {
		int value = 0;
		for (int i = 0; i < bytes.length; i++) {
		   value += ((int) bytes[i] & 0xffL) << (4 * i);
		}
		return value;
	}	
	
	public byte[] extractBytes(byte[] src, int idx, int len) {
		byte[] a = new byte[] {0x0};		
		try {
		    a = Arrays.copyOfRange(src, idx, idx + len);
		}
		catch (Exception e) {
			//
		}
		return a;
	}
	
	public Address convertToAddr(Long lAddr) {
		Address addr = currentProgram.getMinAddress();
		
		return addr = addr.add(lAddr - addr.getOffset()); // a hack, FIXME		
	}
	
	public byte[] readData(MemoryBlock block, Long src, int len) {
		Address addr = convertToAddr(src);
		byte[] data = new byte[(int) len];
		
		try {
			block.getBytes(addr, data);
		}
		catch (MemoryAccessException e) {
			// 
		}
		return data;
	}
	
	public boolean isInBlock(MemoryBlock block, long value) {
		if (value >= block.getStart().getOffset() && value <= block.getEnd().getOffset()) {
			return true;
		}
		else {
			return false;
		}
	}
	
	// main method
    public void run() throws Exception {

		allFunctions = new ArrayList<String>();

		// get .text and .rdata memory segments
		MemoryBlock text_block = getMemoryBlock(".text");
		MemoryBlock rdata_block = getMemoryBlock(".rdata");
		
		// get segments' start and end addresses
		Address text_start = text_block.getStart();
		Address text_end = text_block.getEnd();
		Address rdata_start = rdata_block.getStart();
		Address rdata_end = rdata_block.getEnd();
		
		//Listing pList = currentProgram.getListing();
		String funcName;
		
		// read up .rdata segment
		byte[] rdata_bytes = new byte[(int) rdata_block.getSize()];
		rdata_block.getBytes(rdata_start, rdata_bytes);
		long rdata_size = rdata_block.getSize();

		// start searching for RPC_SERVER_INTERFACE structures
		for (int i = 0; i < rdata_size; i++) {
			// print currently processed address
			Address b = rdata_start.add(i);
			monitor.setMessage(b.toString());
			monitor.checkCanceled();
			
			// get potential RPC_SERVER_INTERFACE struct size, DispatchTable, InterpreterInfo and ServerRoutineTable pointers
			// safety check - dont read over the buffer
			if (i + 8 >= rdata_size) {
				break;
			}
			int rpcStructSize = bytesToInt(extractBytes(rdata_bytes, i, 4));
			Long DispatchTablePtr = bytesToLong(extractBytes(rdata_bytes, i + 0x30, 8));
			Long InterpreterInfoPtr = bytesToLong(extractBytes(rdata_bytes, i + 0x50, 8));
			Long offset = InterpreterInfoPtr - rdata_start.getOffset() + 8;
			Long ServerRoutineTablePtr = bytesToLong(extractBytes(rdata_bytes, offset.intValue() , 8));

			// verify if these pointers are valid
			if (rpcStructSize <= 0 || DispatchTablePtr <= 0 || InterpreterInfoPtr <= 0 || ServerRoutineTablePtr <= 0) {
				continue;
			}
			if (rpcStructSize < 0x100 &&
				isInBlock(rdata_block, DispatchTablePtr) && 
			    isInBlock(rdata_block, InterpreterInfoPtr) && 
				isInBlock(rdata_block, ServerRoutineTablePtr)) {
				
				int dispatchTableCount = bytesToInt(readData(rdata_block, DispatchTablePtr, 4));

				// DispatchTableCount is usually a low value
				if (dispatchTableCount < 500) {					
					for (int j = 0; j < dispatchTableCount; j++) {
						Long funcPtr = bytesToLong(readData(rdata_block, ServerRoutineTablePtr + j*8, 8));
						if (isInBlock(text_block, funcPtr)) {
							try {
								//Function f = pList.getFunctionAt(convertToAddr(funcPtr));
								Function f = getFunctionAt(convertToAddr(funcPtr));
								funcName = f.getName();

								if (f == null) {
									// Weird bug in Ghidra where some functions aren't defined, let's check to see if this is the case for this
                                	if (getSymbolAt(convertToAddr(funcPtr)) != null) {
										// Create our function
										println("[*] Creating function");
										f = createFunction(convertToAddr(funcPtr), null);
										println("[*] Function created with name " + f.getName());
									}
									else {
										println ("[!] Could not find function " + convertToAddr(funcPtr));
										continue;
									}
								}
								else {
									println("[*] Found RPC function " + funcName + " at " + Long.toHexString(funcPtr));
								}

								String strtmp = "";
								strtmp+="{\"Module\":\"" + f.getProgram().getExecutablePath().toString().replace("\\", "/") + "\",";
								strtmp+="\"FunctionType\":\"" + "RPCFunction" + "\",";
								strtmp+="\"FunctionName\":\"" + f.getName() + "\",";
								strtmp+="\"Address\":\"" + f.getEntryPoint().toString() + "\",";
								strtmp+="\"CalledByModule\":\"" + "" + "\",";
								strtmp+="\"CalledBy\":\"" + "" + "\"}";
								allFunctions.add(strtmp);

								// Retrieve functions that this RPC function calls
                            	GetCalled(f,0);

							}
							catch (Exception e) { // When getFunctionAt() used, some functions are not recognized. Ghidra bug?
								funcName = "__UNRESOLVED()";
								println("[!] UNRESOLVED RPC function " + funcName + "," + Long.toHexString(funcPtr));
							}
						}
					}
					i += rpcStructSize - 1;
				}
			}	
		}

		// Write Results to JSON file
		println("[*] Writing to file..");
		File f = new File("AllRpcFuncMaps.json");
        try {
            BufferedWriter bw = new BufferedWriter(new FileWriter(f, true));
			for (String strtmp:allFunctions ) {
				bw.append(strtmp + "\n");
			}
            bw.close();
		}
		catch (IOException e) {
            System.out.println(e.getMessage());
        }
    }
}