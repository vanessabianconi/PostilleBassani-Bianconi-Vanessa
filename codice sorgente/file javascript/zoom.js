const queryString = window.location.search;

const urlParams = new URLSearchParams(queryString);

const page_type = urlParams.get('immagine');

 var viewer = OpenSeadragon({
        id: "seadragon-viewer",
        prefixUrl: "//openseadragon.github.io/openseadragon/images/",
        tileSources: {
            type: 'image',
            url:  "http://localhost:8080/exist/apps/postille/riproduzioni/"+page_type,
            buildPyramid: false
        },
        showNavigator: true,
        showRotationControl: true
    });
