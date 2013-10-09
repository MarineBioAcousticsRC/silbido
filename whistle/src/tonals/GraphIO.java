package tonals;

import java.io.EOFException;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class GraphIO {

	
	public static void saveGraphs(List<graph> graphs, String fileName) throws IOException {
		ObjectOutputStream objectStream = new ObjectOutputStream(new FileOutputStream(fileName));
		
		for (Iterator<graph> iterator = graphs.iterator(); iterator.hasNext();) {
			objectStream.writeObject(iterator.next());
		}
		
		objectStream.close();
	}
	
	public static List<graph> loadGraphs(String fileName) throws IOException, ClassNotFoundException {
		ObjectInputStream objectStream = new ObjectInputStream(new FileInputStream(fileName));
		ArrayList<graph> graphs = new ArrayList<graph>();
		
		
		while (true) {
			try {
				graphs.add((graph) objectStream.readObject());
			} catch (EOFException e) {
				break;
			}
        }
		objectStream.close();
		return graphs;
	}
	
}
