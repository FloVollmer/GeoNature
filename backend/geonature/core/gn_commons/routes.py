'''
    Route permettant de manipuler les fichiers
    contenus dans gn_media
'''

from flask import Blueprint, request, current_app

from geonature.core.gn_commons.repositories import TMediaRepository
from geonature.core.gn_commons.models import TModules
from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import json_resp
from pypnusershub import routes as fnauth
from pypnusershub.db.tools import cruved_for_user_in_app

routes = Blueprint('gn_commons', __name__)


@routes.route('/modules', methods=['GET'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def get_modules(info_role):
    '''
    Return the allowed modules of user from its cruved
    '''
    modules = DB.session.query(TModules).all()
    allowed_modules = []
    for mod in modules:
        app_cruved = cruved_for_user_in_app(
            id_role=info_role.id_role,
            id_application=mod.id_module,
            id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
        )
        if app_cruved['R'] != '0':
            allowed_modules.append(mod.as_dict())
    return allowed_modules


@routes.route('/<int:id_media>', methods=['GET'])
@json_resp
def get_media(id_media):
    '''
        Retourne un media
    '''
    m = TMediaRepository(id_media=id_media).media
    return m.as_dict()


@routes.route('/', methods=['POST', 'PUT'])
@routes.route('/<int:id_media>', methods=['POST', 'PUT'])
@json_resp
def insert_or_update_media(id_media=None):
    '''
        Insertion ou mise à jour d'un média
        avec prise en compte des fichiers joints
    '''
    if request.files:
        file = request.files['file']
    else:
        file = None

    data = {}
    if request.form:
        formData = dict(request.form)
        for key in formData:
            data[key] = formData[key][0]
    else:
        data = request.get_json(silent=True)

    m = TMediaRepository(
        data=data, file=file, id_media=id_media
    ).create_or_update_media()
    return m.as_dict()


@routes.route('/<int:id_media>', methods=['DELETE'])
@json_resp
def delete_media(id_media):
    '''
        Suppression d'un media
    '''
    TMediaRepository(id_media=id_media).delete()
    return {"resp": "media {} deleted".format(id_media)}
