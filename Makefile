gen:
	lpad-gen

clean:
	rm -rf presentation

serve:
	cd presentation && python -m SimpleHTTPServer
