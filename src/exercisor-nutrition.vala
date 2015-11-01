using GLib;
using Sqlite;

public class Nutrition {

    public static int callback (int n_columns, string[] values,
                                string[] column_names)
    {
        for (int i = 0; i < n_columns; i++) {
            stdout.printf ("%s = %s\n", column_names[i], values[i]);
        }

        stdout.printf ("\n");
        return 0;
    }

    private const string query_food = "
		  SELECT * FROM food WHERE long_desc LIKE \"%%%s%%\"
    	";

    private Database db;

    private const string query_nutrients = "
	  SELECT
	    name,
	    units,
	    amount
	  FROM nutrition
	  JOIN nutrient
	  JOIN common_nutrient
	  ON nutrition.food_id = %s
	  AND nutrition.nutrient_id = nutrient.id
	  AND nutrient.id = common_nutrient.id
	";

    public void search_food(string search_word) {
		Statement stmt;
	    int col, cols, rc;
	    if ((rc = db.prepare_v2 (query_food.printf(search_word), -1, out stmt, null)) == 1) {
	        printerr ("SQL error: %d, %s\n", rc, db.errmsg ());
	        return;
	    }
		cols = stmt.column_count();
	    do {
	        rc = stmt.step();
	        switch (rc) {
	        case Sqlite.DONE:
	            break;
	        case Sqlite.ROW:
	            for (col = 0; col < cols; col++) {
	                string txt = stmt.column_text(col);
	                if(stmt.column_name(col) == "id") {
	                	print("ID!");
	                }
	                print ("%s = %s\n", stmt.column_name (col), txt);
	            }
	            break;
	        default:
	            printerr ("Error: %d, %s\n", rc, db.errmsg ());
	            break;
	        }
	    } while (rc == Sqlite.ROW);

    	// rc = db.exec (query_food.printf(search_word), callback, null);

    }

    public Nutrition(string db_name) {
    	
    	int rc = Database.open (db_name, out db);

    	if (rc != Sqlite.OK) {
    	    stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
    	    // return 1;
    	}


    }

    public static int main (string[] args) {

        int rc;

        if (args.length != 3) {
            stderr.printf ("Usage: %s DATABASE SQL-STATEMENT\n", args[0]);
            return 1;
        }

        if (!FileUtils.test (args[1], FileTest.IS_REGULAR)) {
            stderr.printf ("Database %s does not exist or is directory\n", args[1]);
            return 1;
        }

        var obj = new Nutrition(args[1]);
        obj.search_food(args[2]);


        // rc = db.exec (search_food.printf(args[2]), callback, null);
        // print(search_food.printf(args[2]));
        /* maybe it is better to use closures, so you can access local variables, eg: */
        /*rc = db.exec(args[2], (n_columns, values, column_names) => {
            for (int i = 0; i < n_columns; i++) {
                stdout.printf ("%s = %s\n", column_names[i], values[i]);
            }
            stdout.printf ("\n");

            return 0;
            }, null);
        */

        // if (rc != Sqlite.OK) { 
        //     stderr.printf ("SQL error: %d, %s\n", rc, db.errmsg ());
        //     return 1;
        // }

        return 0;
    }
}